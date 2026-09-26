import { StatusCodes } from 'http-status-codes';
import { Types } from 'mongoose';
import { S3Client, DeleteObjectCommand } from '@aws-sdk/client-s3';
import config from '../../../config';
import ApiError from '../../../errors/ApiError';
import {
  createLiveKitToken,
  startLiveKitRecording,
  stopLiveKitRecording,
  verifyLiveKitWebhook,
} from '../../../helpers/livekit.helper';
import { socketHelper } from '../../../helpers/socketHelper';
import { User } from '../user/user.model';
import { Meeting } from './meeting.model';
import { IMeeting } from './meeting.interface';
import { Conversation } from '../conversation/conversation.model';
import { Message } from '../message/message.model';
import { NotificationService } from '../notification/notification.service';
import { VaultFolder } from '../vault/vaultFolder.model';
import { VaultItem } from '../vault/vaultItem.model';
import { debug, debugError } from '../../../shared/debug';
import { USER_ROLES } from '../../../enums/user';
import { SubscriptionService } from '../subscription/subscription.service';

// ─── S3 client (used for deleting recordings when a meeting is removed) ──────
const s3 = new S3Client({
  region: process.env.S3_REGION || process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY || process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.S3_SECRET_KEY || process.env.AWS_SECRET_ACCESS_KEY || '',
  },
});
const S3_BUCKET = process.env.S3_BUCKET || process.env.AWS_BUCKET || 'govia-meeting-recordings';

/**
 * Extract the S3 object key from any recording URL format:
 *   s3://bucket/key/file.mp4        → key/file.mp4
 *   https://bucket.s3.region.amazonaws.com/key/file.mp4 → key/file.mp4
 *   https://s3.amazonaws.com/bucket/key/file.mp4        → key/file.mp4
 */
function extractS3Key(url: string): string | null {
  try {
    if (url.startsWith('s3://')) {
      // s3://bucket/key → everything after the second slash
      const withoutScheme = url.slice(5); // 'bucket/key/file.mp4'
      const slashIdx = withoutScheme.indexOf('/');
      return slashIdx === -1 ? null : withoutScheme.slice(slashIdx + 1);
    }
    const parsed = new URL(url);
    // https://bucket.s3[.region].amazonaws.com/key
    if (parsed.hostname.endsWith('.amazonaws.com')) {
      const path = parsed.pathname.slice(1); // remove leading /
      // If hostname starts with the bucket name, pathname IS the key.
      // If it's s3.amazonaws.com/bucket/key, strip the bucket prefix.
      if (parsed.hostname.startsWith('s3.') || parsed.hostname.startsWith('s3-')) {
        const parts = path.split('/');
        return parts.slice(1).join('/'); // drop bucket segment
      }
      return path;
    }
    return null;
  } catch {
    return null;
  }
}

/** Delete all S3 recording files attached to a meeting. Errors are swallowed. */
async function deleteS3RecordingFiles(meeting: IMeeting): Promise<void> {
  const urls: string[] = [];

  if (meeting.recordingUrl) urls.push(meeting.recordingUrl);
  if (Array.isArray(meeting.recordings)) {
    for (const r of meeting.recordings) {
      if (r.playUrl) urls.push(r.playUrl);
      if (r.downloadUrl && r.downloadUrl !== r.playUrl) urls.push(r.downloadUrl);
    }
  }

  const uniqueUrls = [...new Set(urls.filter(Boolean))];
  if (uniqueUrls.length === 0) return;

  await Promise.allSettled(
    uniqueUrls.map(async url => {
      const key = extractS3Key(url);
      if (!key) return;
      try {
        await s3.send(new DeleteObjectCommand({ Bucket: S3_BUCKET, Key: key }));
        debug(`[Meeting] 🗑 Deleted S3 object: ${key}`);
      } catch (err) {
        debugError(`[Meeting] S3 delete failed for key "${key}":`, (err as Error)?.message);
      }
    })
  );
}

const createInstantMeeting = async (
  userId: string,
  topic = 'Instant Govia Consultation',
  participantId?: string,
  isEmergency = false,
  conversationId?: string,
  latitude?: number,
  longitude?: number,
  locationAddress?: string,
  preferredAttorney?: string,
  preferredBailBondsman?: string
) => {
  let participantObjectId: Types.ObjectId | undefined;
  if (participantId) {
    const participant = await User.findById(participantId);
    if (!participant) {
      throw new ApiError(StatusCodes.NOT_FOUND, 'Participant user not found');
    }
    participantObjectId = new Types.ObjectId(participantId);
  }

  let convObjectId: Types.ObjectId | undefined;
  if (conversationId && Types.ObjectId.isValid(conversationId)) {
    const conversation = await Conversation.findById(conversationId);
    if (conversation) {
      convObjectId = conversation._id;
      if (!participantObjectId) {
        const otherP = conversation.participants.find(
          p => p.toString() !== userId
        );
        if (otherP) participantObjectId = otherP;
      }
    }
  }

  const hostUser = await User.findById(userId);
  if (!hostUser) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Host user not found');
  }

  // Quota enforcement: ONLY apply to Citizen role. Professional roles are completely exempt.
  const quotaCheck = await SubscriptionService.checkCitizenMeetingQuota(
    userId,
    hostUser.role
  );
  if (!quotaCheck.allowed) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      quotaCheck.reason ||
        'You have reached your limit of 3 free emergency/Govia meetings this month. Upgrade to Premium for unlimited emergency protection.'
    );
  }

  const roomName = `govia_${Date.now()}_${userId.slice(-6)}`;

  // Retire any prior active meetings for this host so stale duplicate live incidents do not linger
  await Meeting.updateMany(
    { userId: new Types.ObjectId(userId), status: 'ACTIVE' },
    { status: 'COMPLETED', endedAt: new Date() }
  );

  try {
    const newMeeting = await Meeting.create({
      userId: new Types.ObjectId(userId),
      participantId: participantObjectId,
      conversationId: convObjectId,
      roomName,
      sessionName: roomName,
      topic,
      meetingType: isEmergency ? 'EMERGENCY' : 'INSTANT',
      category: isEmergency
        ? 'EMERGENCY'
        : topic.toLowerCase().includes('govia')
          ? 'ENCOUNTER'
          : 'CONSULTATION',
      status: 'ACTIVE',
      latitude,
      longitude,
      locationAddress,
    });

    // Atomically increment monthly meeting quota count for citizens
    await SubscriptionService.incrementCitizenMeetingCount(
      userId,
      hostUser.role
    );

    const populatedMeeting = await Meeting.findById(newMeeting._id)
      .populate('userId', 'name email role image phoneNumber')
      .populate('participantId', 'name email role image phoneNumber')
      .populate('vaultFolderId', 'name description category')
      .populate('conversationId');

    const livekitToken = await createLiveKitToken({
      roomName,
      participantIdentity: userId,
      participantName: hostUser?.name || 'Citizen',
    });

    const meetingResult: Record<string, unknown> = populatedMeeting
      ? populatedMeeting.toObject()
      : newMeeting.toObject();
    meetingResult.meetingId = newMeeting._id;
    meetingResult.sessionName = roomName;
    meetingResult.roomName = roomName;
    meetingResult.token = livekitToken;
    meetingResult.livekitToken = livekitToken;
    meetingResult.livekitUrl = config.livekit.url;
    meetingResult.latitude = newMeeting.latitude;
    meetingResult.longitude = newMeeting.longitude;
    meetingResult.locationAddress = newMeeting.locationAddress;

    // If meeting is attached to a conversation thread, automatically post meeting message card
    if (convObjectId && participantObjectId) {
      const chatMessage = await Message.create({
        conversationId: convObjectId,
        sender: new Types.ObjectId(userId),
        receiver: participantObjectId,
        messageType: 'meeting',
        meetingId: newMeeting._id,
        text: isEmergency
          ? '🚨 Emergency Meeting Started'
          : `📞 Instant Meeting Started: ${topic}`,
        read: false,
      });

      await Conversation.findByIdAndUpdate(convObjectId, {
        lastMessage: chatMessage._id,
        lastMessageText: isEmergency
          ? '🚨 Emergency Meeting'
          : '📞 Instant Meeting',
        lastMessageAt: new Date(),
      });

      const populatedMessage = await Message.findById(chatMessage._id)
        .populate('sender', 'name email role image')
        .populate('receiver', 'name email role image')
        .populate('meetingId');

      socketHelper.emitToConversation(
        convObjectId.toString(),
        'new_message',
        populatedMessage
      );

      socketHelper.emitToUser(
        participantObjectId.toString(),
        'inbox_update',
        {
          conversationId: convObjectId.toString(),
          lastMessage: populatedMessage,
          lastMessageText: isEmergency
            ? '🚨 Emergency Meeting'
            : '📞 Instant Meeting',
          lastMessageAt: new Date(),
        }
      );
    }

    // Real-time socket notification & persistent notification records for all roles
    if (isEmergency) {
      socketHelper.emitToRole('ATTORNEY', 'emergency_alert', meetingResult);
      socketHelper.emitToRole('POLICE', 'emergency_alert', meetingResult);
      socketHelper.emitToRole('MENTAL_HEALTH_PROFESSIONAL', 'emergency_alert', meetingResult);
      socketHelper.emitToRole('BAIL_BONDSMAN', 'emergency_alert', meetingResult);
      if (preferredAttorney && Types.ObjectId.isValid(preferredAttorney)) {
        socketHelper.emitToUser(preferredAttorney, 'emergency_alert', meetingResult);
      }
      if (preferredBailBondsman && Types.ObjectId.isValid(preferredBailBondsman)) {
        socketHelper.emitToUser(preferredBailBondsman, 'emergency_alert', meetingResult);
      }
      socketHelper.broadcast('emergency_meeting_created', meetingResult);

      const hostName = hostUser?.name || 'Citizen';
      const hostAvatar = hostUser?.image || '';
      const loc = locationAddress || 'Active GPS Location';
      const meetingId = newMeeting._id.toString();

      // 1. Citizen's own active protection notification
      NotificationService.createNotification({
        userId,
        type: 'emergency',
        title: '🛡️ Govia Active Protection Enabled',
        subtitle: `Live encounter active at ${loc}. Responders alerted and cloud recording started.`,
        resourceType: 'encounter',
        resourceId: meetingId,
        metadata: {
          callerName: hostName,
          callerRole: 'CITIZEN',
          callerAvatar: hostAvatar,
          location: loc,
          meetingId,
          topic,
          category: 'EMERGENCY',
          isLive: true,
        },
      });

      // 2. Police notification
      NotificationService.createRoleNotification('POLICE', {
        type: 'dispatch',
        title: `🚨 Emergency Stop Encounter: ${hostName}`,
        subtitle: `Citizen ${hostName} initiated an emergency encounter at ${loc}. Live video & GPS streaming.`,
        resourceType: 'encounter',
        resourceId: meetingId,
        metadata: {
          callerName: hostName,
          callerRole: 'CITIZEN',
          callerAvatar: hostAvatar,
          location: loc,
          meetingId,
          topic,
          category: 'EMERGENCY',
          isLive: true,
        },
      }, userId);

      // 3. Attorney notification
      NotificationService.createRoleNotification('ATTORNEY', {
        type: 'legal',
        title: `⚖️ Emergency Defense Dispatch: ${hostName}`,
        subtitle: `Citizen ${hostName} requested emergency legal representation during a live stop at ${loc}. Tap to review details & join call.`,
        resourceType: 'meeting',
        resourceId: meetingId,
        metadata: {
          callerName: hostName,
          callerRole: 'CITIZEN',
          callerAvatar: hostAvatar,
          location: loc,
          meetingId,
          topic,
          category: 'EMERGENCY',
          isLive: true,
        },
      }, userId);

      // 4. Mental Health notification
      NotificationService.createRoleNotification('MENTAL_HEALTH_PROFESSIONAL', {
        type: 'medical',
        title: `🩺 Crisis De-escalation Alert: ${hostName}`,
        subtitle: `Mental health crisis support requested for active encounter with citizen ${hostName} at ${loc}.`,
        resourceType: 'meeting',
        resourceId: meetingId,
        metadata: {
          callerName: hostName,
          callerRole: 'CITIZEN',
          callerAvatar: hostAvatar,
          location: loc,
          meetingId,
          topic,
          category: 'EMERGENCY',
          isLive: true,
        },
      }, userId);

      // 5. Bail Bondsman notification
      NotificationService.createRoleNotification('BAIL_BONDSMAN', {
        type: 'bail',
        title: `🏛️ Urgent Bail Assistance Notice: ${hostName}`,
        subtitle: `Citizen ${hostName} initiated an emergency stop at ${loc} in your service jurisdiction.`,
        resourceType: 'meeting',
        resourceId: meetingId,
        metadata: {
          callerName: hostName,
          callerRole: 'CITIZEN',
          callerAvatar: hostAvatar,
          location: loc,
          meetingId,
          topic,
          category: 'EMERGENCY',
          isLive: true,
        },
      }, userId);
    } else if (participantId) {
      socketHelper.emitToUser(
        participantId,
        'instant_meeting_invite',
        meetingResult
      );
      const hostName = hostUser?.name || 'User';
      const hostAvatar = hostUser?.image || '';
      NotificationService.createNotification({
        userId: participantId,
        type: 'consultation',
        title: `📞 Instant Consultation Call: ${hostName}`,
        subtitle: `${hostName} started an instant video consultation: "${topic}". Tap to join call.`,
        resourceType: 'meeting',
        resourceId: newMeeting._id.toString(),
        metadata: {
          callerName: hostName,
          callerAvatar: hostAvatar,
          topic,
          meetingId: newMeeting._id.toString(),
          isLive: true,
        },
      });
    } else {
      socketHelper.emitToRole('ATTORNEY', 'emergency_alert', meetingResult);
      socketHelper.emitToRole('POLICE', 'emergency_alert', meetingResult);
      socketHelper.emitToRole('MENTAL_HEALTH_PROFESSIONAL', 'emergency_alert', meetingResult);
      socketHelper.emitToRole('BAIL_BONDSMAN', 'emergency_alert', meetingResult);
      socketHelper.broadcast('emergency_meeting_created', meetingResult);
    }

    // Auto-start cloud Egress recording in background if storage is configured
    try {
      startLiveKitRecording(roomName).then(async (egressInfo) => {
        if (egressInfo?.egressId) {
          await Meeting.findByIdAndUpdate(newMeeting._id, {
            egressId: String(egressInfo.egressId),
          });
          debug(`[Meeting] Auto-started egress ${egressInfo.egressId} for meeting ${newMeeting._id}`);
        }
      }).catch(err => {
        debugError('[Meeting] Auto-recording background start notice:', err instanceof Error ? err.message : String(err));
      });
    } catch (err) {
      debugError('[Meeting] Auto-recording synchronous start error:', err instanceof Error ? err.message : String(err));
    }

    return meetingResult;
  } catch (error: unknown) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      'Error creating meeting room'
    );
  }
};

const scheduleMeeting = async (
  userId: string,
  payload: {
    participantId?: string;
    conversationId?: string;
    topic: string;
    startTime: string;
    durationMinutes?: number;
    timezone?: string;
    agenda?: string;
  }
) => {
  const {
    participantId,
    conversationId,
    topic,
    startTime,
    durationMinutes = 30,
    timezone = 'UTC',
    agenda,
  } = payload;

  const meetingDate = new Date(startTime);
  if (isNaN(meetingDate.getTime())) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid startTime format');
  }

  let participantObjectId: Types.ObjectId | undefined;
  if (participantId) {
    const participant = await User.findById(participantId);
    if (!participant) {
      throw new ApiError(StatusCodes.NOT_FOUND, 'Participant user not found');
    }
    participantObjectId = new Types.ObjectId(participantId);
  }

  let convObjectId: Types.ObjectId | undefined;
  if (conversationId && Types.ObjectId.isValid(conversationId)) {
    const conversation = await Conversation.findById(conversationId);
    if (conversation) {
      convObjectId = conversation._id;
      if (!participantObjectId) {
        const otherP = conversation.participants.find(
          p => p.toString() !== userId
        );
        if (otherP) participantObjectId = otherP;
      }
    }
  }

  const hostUser = await User.findById(userId);
  const isCitizen =
    hostUser?.role === USER_ROLES.CITIZEN || hostUser?.role === USER_ROLES.USER;
  if (isCitizen) {
    let isDoctorConsultation = false;
    if (participantObjectId) {
      const participant = await User.findById(participantObjectId);
      if (
        participant?.role === USER_ROLES.MENTAL_HEALTH_PROFESSIONAL ||
        (participant?.role as string) === 'DOCTOR'
      ) {
        isDoctorConsultation = true;
      }
    }
    if (topic && /mental health|therapy|doctor|psychiat|counsel/i.test(topic)) {
      isDoctorConsultation = true;
    }

    if (isDoctorConsultation) {
      const subStatus = await SubscriptionService.getUserSubscriptionStatus(
        userId,
        hostUser?.role
      );
      if (!subStatus.features.hasDoctorSupport) {
        throw new ApiError(
          StatusCodes.FORBIDDEN,
          'Mental health support and doctor appointments require Govia Premium. Please upgrade your subscription.'
        );
      }
    }
  }

  const roomName = `govia_scheduled_${Date.now()}_${userId.slice(-6)}`;

  try {
    const scheduledMeeting = await Meeting.create({
      userId: new Types.ObjectId(userId),
      participantId: participantObjectId,
      conversationId: convObjectId,
      roomName,
      sessionName: roomName,
      topic,
      meetingType: 'SCHEDULED',
      category: 'CONSULTATION',
      startTime: meetingDate,
      durationMinutes,
      timezone,
      agenda,
      status: 'SCHEDULED',
    });

    const populatedMeeting = await Meeting.findById(scheduledMeeting._id)
      .populate('userId', 'name email role image phoneNumber')
      .populate('participantId', 'name email role image phoneNumber')
      .populate('vaultFolderId', 'name description category')
      .populate('conversationId');

    const scheduledResult = populatedMeeting
      ? populatedMeeting.toObject()
      : scheduledMeeting.toObject();
    scheduledResult.sessionName = roomName;
    scheduledResult.roomName = roomName;

    // If meeting is attached to a conversation thread, automatically post meeting message card
    if (convObjectId && participantObjectId) {
      const chatMessage = await Message.create({
        conversationId: convObjectId,
        sender: new Types.ObjectId(userId),
        receiver: participantObjectId,
        messageType: 'meeting',
        meetingId: scheduledMeeting._id,
        text: `📅 Meeting Scheduled: ${topic} (${meetingDate.toLocaleString()})`,
        read: false,
      });

      await Conversation.findByIdAndUpdate(convObjectId, {
        lastMessage: chatMessage._id,
        lastMessageText: `📅 Meeting Scheduled: ${topic}`,
        lastMessageAt: new Date(),
      });

      const populatedMessage = await Message.findById(chatMessage._id)
        .populate('sender', 'name email role image')
        .populate('receiver', 'name email role image')
        .populate('meetingId');

      socketHelper.emitToConversation(
        convObjectId.toString(),
        'new_message',
        populatedMessage
      );

      socketHelper.emitToUser(
        participantObjectId.toString(),
        'inbox_update',
        {
          conversationId: convObjectId.toString(),
          lastMessage: populatedMessage,
          lastMessageText: `📅 Meeting Scheduled: ${topic}`,
          lastMessageAt: new Date(),
        }
      );
    }

    if (participantId) {
      socketHelper.emitToUser(
        participantId,
        'new_meeting_invite',
        scheduledResult
      );

      const hostUser = await User.findById(userId);
      const hostName = hostUser?.name || 'Professional';
      const participantUser = await User.findById(participantId);
      const participantName = participantUser?.name || 'Client';

      // 1. Participant notification
      NotificationService.createNotification({
        userId: participantId,
        type: 'consultation',
        title: `📅 Consultation Scheduled: ${topic}`,
        subtitle: `${hostName} scheduled "${topic}" for ${meetingDate.toLocaleDateString()} at ${meetingDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}.`,
        resourceType: 'meeting',
        resourceId: scheduledMeeting._id.toString(),
        metadata: {
          callerName: hostName,
          topic,
          meetingDate: meetingDate.toISOString(),
          isLive: false,
        },
      });

      // 2. Host confirmation notification
      NotificationService.createNotification({
        userId,
        type: 'consultation',
        title: `📅 Consultation Confirmed: ${topic}`,
        subtitle: `Consultation with ${participantName} confirmed for ${meetingDate.toLocaleDateString()} at ${meetingDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}.`,
        resourceType: 'meeting',
        resourceId: scheduledMeeting._id.toString(),
        metadata: {
          callerName: participantName,
          topic,
          meetingDate: meetingDate.toISOString(),
          isLive: false,
        },
      });
    }

    return scheduledResult;
  } catch (error: unknown) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      'Error scheduling Zoom meeting'
    );
  }
};

const getActiveMeetings = async () => {
  const activeMeetings = await Meeting.find({
    status: 'ACTIVE',
    $or: [
      { category: { $in: ['ENCOUNTER', 'EMERGENCY'] } },
      { meetingType: 'EMERGENCY' },
      { topic: { $regex: /police|encounter|emergency|unsafe|stopped|govia/i } },
    ],
    category: { $ne: 'CONSULTATION' },
  })
    .sort({ createdAt: -1 })
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('conversationId');

  // De-duplicate meetings by host userId so only the most recent active request appears
  const seenUsers = new Set<string>();
  const uniqueActiveMeetings: typeof activeMeetings = [];
  for (const m of activeMeetings) {
    const uId =
      (m.userId as unknown as { _id?: { toString(): string } })?._id?.toString() ||
      m.userId?.toString();
    if (uId && !seenUsers.has(uId)) {
      seenUsers.add(uId);
      uniqueActiveMeetings.push(m);
    } else if (!uId) {
      uniqueActiveMeetings.push(m);
    }
  }
  return uniqueActiveMeetings;
};

const getUserMeetings = async (
  userId: string,
  query: {
    status?: string;
    meetingType?: string;
    timeFilter?: string;
    isConsultationOnly?: string | boolean;
    includeEmergency?: string | boolean;
    page?: number | string;
    limit?: number | string;
  } = {}
) => {
  const userObjectId = new Types.ObjectId(userId);

  const filter: Record<string, unknown> = {
    $or: [
      { userId: userObjectId },
      { participantId: userObjectId },
      { joinedAttorneys: userObjectId },
      { joinedParticipants: userObjectId },
    ],
  };

  // 1. Meeting Type filtering & Emergency exclusion
  if (query.meetingType) {
    if (query.includeEmergency !== 'true' && query.meetingType === 'EMERGENCY') {
      filter.meetingType = { $in: [] }; // Cannot return emergency meetings when emergency exclusion is active
    } else {
      filter.meetingType = query.meetingType;
    }
  } else if (query.includeEmergency !== 'true') {
    filter.meetingType = { $ne: 'EMERGENCY' };
  }

  // Schedule filtering: Consultation Schedule strictly excludes emergency SOS calls,
  // Start Govia encounters, and panic cards (e.g. 'I feel unsafe' / 'I'm being stopped').
  // These incident recordings belong exclusively to the Evidence Vault Recordings.
  if (query.includeEmergency !== 'true') {
    filter.category = { $nin: ['EMERGENCY', 'ENCOUNTER'] };
    filter.topic = {
      $not: {
        $regex: /emergency|unsafe|stopped|start govia|encounter|incident protocol/i,
      },
    };
  }

  // 2. Status & TimeFilter filtering
  if (query.status) {
    filter.status = query.status;
  } else if (query.timeFilter === 'upcoming') {
    filter.status = { $in: ['SCHEDULED', 'ACTIVE'] };
  } else if (query.timeFilter === 'past') {
    filter.status = { $in: ['COMPLETED', 'CANCELLED'] };
  }

  const page = Number(query.page) || 1;
  const limit = Number(query.limit) || 20;
  const skip = (page - 1) * limit;

  let meetingQuery = Meeting.find(filter)
    .sort({
      startTime: query.timeFilter === 'upcoming' ? 1 : -1,
      createdAt: -1,
    })
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('joinedAttorneys', 'name email role image')
    .populate('vaultFolderId', 'name description category')
    .populate('conversationId');

  if (query.page && query.limit) {
    meetingQuery = meetingQuery.skip(skip).limit(limit);
  }

  const rawMeetings = await meetingQuery.lean();

  const user = await User.findById(userId);
  const isCitizen =
    user?.role === USER_ROLES.CITIZEN || user?.role === USER_ROLES.USER;
  let canViewRecordings = true;
  if (isCitizen) {
    const subStatus = await SubscriptionService.getUserSubscriptionStatus(
      userId,
      user?.role
    );
    canViewRecordings = subStatus.features.canViewRecordings;
  }

  const meetings = rawMeetings.map((m: Record<string, unknown>) => {
    if (isCitizen && !canViewRecordings) {
      return {
        ...m,
        recordingUrl: null,
        recordings: [],
        isRecordingLocked: true,
      };
    }
    return {
      ...m,
      isRecordingLocked: false,
    };
  });

  if (query.page && query.limit) {
    const total = await Meeting.countDocuments(filter);
    return {
      meta: {
        page,
        limit,
        total,
        totalPage: Math.ceil(total / limit),
      },
      data: meetings,
    };
  }

  return meetings;
};

const joinMeeting = async (meetingId: string, userId: string) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  // Reject immediately if the meeting was already ended or cancelled
  if (
    meeting.status === 'COMPLETED' ||
    meeting.status === 'CANCELLED' ||
    meeting.endedAt
  ) {
    throw new ApiError(
      StatusCodes.GONE,
      'This meeting has ended and is no longer available to join.'
    );
  }

  const user = await User.findById(userId);
  const userObjectId = new Types.ObjectId(userId);

  // If host joins / rejoins, cancel any pending 5-minute auto-end timer
  if (meeting.userId.toString() === userId) {
    await hostRejoinedMeeting(meetingId, userId);
  }

  // If joiner is not the creator, register them as joined participant
  if (meeting.userId.toString() !== userId) {
    let shouldSave = false;

    if (!meeting.joinedParticipants) {
      meeting.joinedParticipants = [];
    }
    if (!meeting.joinedParticipants.some(id => id.equals(userObjectId))) {
      meeting.joinedParticipants.push(userObjectId);
      shouldSave = true;
    }

    if (user?.role === 'ATTORNEY') {
      if (!meeting.joinedAttorneys) {
        meeting.joinedAttorneys = [];
      }
      if (!meeting.joinedAttorneys.some(id => id.equals(userObjectId))) {
        meeting.joinedAttorneys.push(userObjectId);
        shouldSave = true;
      }
    }

    if (!meeting.participantId) {
      meeting.participantId = userObjectId;
      shouldSave = true;
    }

    if (shouldSave) {
      await meeting.save();
    }
  }

  const roomName = meeting.roomName || meeting.sessionName || `govia_${meeting._id}`;
  const livekitToken = await createLiveKitToken({
    roomName,
    participantIdentity: userId,
    participantName: user?.name || 'Participant',
  });

  socketHelper.emitToUser(meeting.userId.toString(), 'meeting_joined', {
    meetingId: meeting._id,
    userId,
    userName: user?.name,
  });

  const populatedMeeting = await Meeting.findById(meeting._id)
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('joinedAttorneys', 'name email role image')
    .populate('joinedParticipants', 'name email role image phoneNumber');

  const meetingData: Record<string, unknown> = populatedMeeting
    ? populatedMeeting.toObject()
    : meeting.toObject();

  return {
    ...meetingData,
    meetingId: meeting._id,
    roomName,
    sessionName: roomName,
    token: livekitToken,
    livekitToken,
    livekitUrl: config.livekit.url,
    joinUrl: meeting.joinUrl,
  };
};

const updateMeeting = async (
  userId: string,
  meetingId: string,
  payload: {
    topic?: string;
    startTime?: string;
    durationMinutes?: number;
    timezone?: string;
    agenda?: string;
    latitude?: number;
    longitude?: number;
    locationAddress?: string;
  }
) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  const userObjectId = new Types.ObjectId(userId);
  const isHost = meeting.userId.equals(userObjectId);
  const isParticipant =
    meeting.participantId && meeting.participantId.equals(userObjectId);

  if (!isHost && !isParticipant) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You do not have permission to edit this meeting'
    );
  }

  if (payload.topic) meeting.topic = payload.topic;
  if (payload.startTime) {
    const meetingDate = new Date(payload.startTime);
    if (isNaN(meetingDate.getTime())) {
      throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid startTime format');
    }
    meeting.startTime = meetingDate;
  }
  if (payload.durationMinutes !== undefined) {
    meeting.durationMinutes = Number(payload.durationMinutes);
  }
  if (payload.timezone) meeting.timezone = payload.timezone;
  if (payload.agenda !== undefined) meeting.agenda = payload.agenda;
  if (payload.latitude !== undefined) meeting.latitude = Number(payload.latitude);
  if (payload.longitude !== undefined) meeting.longitude = Number(payload.longitude);
  if (payload.locationAddress !== undefined) meeting.locationAddress = payload.locationAddress;

  await meeting.save();

  if (payload.latitude !== undefined || payload.longitude !== undefined) {
    socketHelper.broadcast('meeting_location_updated', {
      meetingId: meeting._id,
      latitude: meeting.latitude,
      longitude: meeting.longitude,
      locationAddress: meeting.locationAddress,
    });
  }

  await Message.updateMany(
    { meetingId: meeting._id },
    {
      text: `📅 Meeting Updated: ${meeting.topic}\n🕒 Time: ${new Date(
        meeting.startTime || Date.now()
      ).toLocaleString()}\n⏱ Duration: ${meeting.durationMinutes} minutes${
        meeting.agenda ? `\n📝 Agenda: ${meeting.agenda}` : ''
      }`,
      isEdited: true,
    }
  );

  const populatedMeeting = await Meeting.findById(meeting._id)
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('joinedAttorneys', 'name email role image')
    .populate('conversationId');

  if (meeting.conversationId) {
    socketHelper.emitToConversation(
      meeting.conversationId.toString(),
      'meeting_updated',
      populatedMeeting
    );
  }

  return populatedMeeting;
};

const deleteMeeting = async (userId: string, meetingId: string) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  const user = await User.findById(userId);
  const isAdmin =
    user &&
    (user.role === USER_ROLES.ADMIN || user.role === USER_ROLES.SUPER_ADMIN);

  const userObjectId = new Types.ObjectId(userId);
  const isHost = meeting.userId.equals(userObjectId);
  const isParticipant =
    meeting.participantId && meeting.participantId.equals(userObjectId);

  if (!isHost && !isParticipant && !isAdmin) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You do not have permission to delete this meeting'
    );
  }

  await Message.updateMany(
    { meetingId: meeting._id },
    { isDeleted: true, text: 'This meeting was deleted' }
  );

  // Delete any recording files from S3 before removing the DB record
  await deleteS3RecordingFiles(meeting);

  await Meeting.findByIdAndDelete(meetingId);

  if (meeting.conversationId) {
    socketHelper.emitToConversation(
      meeting.conversationId.toString(),
      'meeting_deleted',
      { meetingId }
    );
  }

  return { message: 'Meeting deleted successfully', meetingId };
};

// Active 5-minute auto-end timers for meetings where host left without ending
const hostLeaveTimers = new Map<string, NodeJS.Timeout>();

const hostLeaveMeeting = async (meetingId: string, userId: string) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) return;

  if (meeting.userId.toString() === userId && meeting.status === 'ACTIVE') {
    if (hostLeaveTimers.has(meetingId)) {
      clearTimeout(hostLeaveTimers.get(meetingId)!);
      hostLeaveTimers.delete(meetingId);
    }

    debug('meeting.host_left.5min_timer_started', { meetingId });

    const timer = setTimeout(async () => {
      try {
        const currentMeeting = await Meeting.findById(meetingId);
        if (currentMeeting && currentMeeting.status === 'ACTIVE') {
          debug('meeting.auto_end_5min_triggered', { meetingId });
          await endMeeting(currentMeeting.userId.toString(), meetingId);
        }
      } catch (err) {
        debug('meeting.auto_end_5min_error', { meetingId, error: err });
      } finally {
        hostLeaveTimers.delete(meetingId);
      }
    }, 5 * 60 * 1000); // 5 minutes

    hostLeaveTimers.set(meetingId, timer);
  }
};

const hostRejoinedMeeting = async (meetingId: string, userId: string) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }
  if (
    meeting.status === 'COMPLETED' ||
    meeting.status === 'CANCELLED' ||
    meeting.endedAt
  ) {
    throw new ApiError(
      StatusCodes.GONE,
      'This meeting has ended and cannot be rejoined.'
    );
  }

  if (hostLeaveTimers.has(meetingId)) {
    clearTimeout(hostLeaveTimers.get(meetingId)!);
    hostLeaveTimers.delete(meetingId);
    debug('meeting.host_rejoined.timer_cancelled', { meetingId, userId });
  }
};

const leaveMeeting = async (meetingId: string, userId: string) => {
  if (!Types.ObjectId.isValid(meetingId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid meeting ID format');
  }

  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  const userObjectId = new Types.ObjectId(userId);
  const isHost = meeting.userId.equals(userObjectId);

  if (isHost) {
    // Host disconnected/left without ending: start 5-minute grace auto-end
    await hostLeaveMeeting(meetingId, userId);
    return { message: 'Host left meeting. Will auto-end in 5 minutes if not rejoined.', isHost: true, meetingId };
  }

  // Participant leaves: remove from active attendees without ending the session for the host
  if (meeting.joinedParticipants) {
    meeting.joinedParticipants = meeting.joinedParticipants.filter(id => !id.equals(userObjectId));
  }
  if (meeting.joinedAttorneys) {
    meeting.joinedAttorneys = meeting.joinedAttorneys.filter(id => !id.equals(userObjectId));
  }
  await meeting.save();

  socketHelper.emitToUser(meeting.userId.toString(), 'participant_left', {
    meetingId: meeting._id,
    userId,
  });

  return { message: 'Left meeting successfully', isHost: false, meetingId };
};

const endMeeting = async (userId: string, meetingId: string) => {
  if (!Types.ObjectId.isValid(meetingId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid meeting ID format');
  }

  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  const userObjectId = new Types.ObjectId(userId);
  const isHost = meeting.userId.equals(userObjectId);
  const isParticipant =
    meeting.participantId && meeting.participantId.equals(userObjectId);
  const isJoinedAttorney = meeting.joinedAttorneys?.some(id =>
    id.equals(userObjectId)
  );
  const isJoinedParticipant = meeting.joinedParticipants?.some(id =>
    id.equals(userObjectId)
  );

  if (!isHost && !isParticipant && !isJoinedAttorney && !isJoinedParticipant) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You do not have permission to end this meeting'
    );
  }

  // If a joined participant taps end/leave, treat it as leaveMeeting so the host's encounter stays active!
  if (!isHost) {
    return await leaveMeeting(meetingId, userId);
  }

  // Host explicitly ends meeting: cancel any pending auto-end timer
  if (hostLeaveTimers.has(meetingId)) {
    clearTimeout(hostLeaveTimers.get(meetingId)!);
    hostLeaveTimers.delete(meetingId);
  }

  meeting.status = 'COMPLETED';
  meeting.endedAt = new Date();

  // ── Stop Egress and poll for S3 file URL ────────────────────────────────
  // LiveKit Cloud cannot reach a private IP to deliver webhooks, so we poll
  // the Egress API directly after stopping to get the recording S3 URL.
  if (meeting.egressId) {
    try {
      await stopLiveKitRecording(meeting.egressId);
      debug(`[Meeting] Stopped Egress ${meeting.egressId}. Polling for S3 file URL...`);

      // Poll up to 30 seconds (6 × 5s) waiting for the egress to reach COMPLETE state
      let dbSetting, apiKey, apiSecret, livekitUrl;
      try {
        dbSetting = await import('../storageSetting/storageSetting.model').then(m => m.StorageSetting.findOne().sort({ updatedAt: -1 }));
        apiKey = dbSetting?.livekitApiKey || config.livekit.apiKey;
        apiSecret = dbSetting?.livekitApiSecret || config.livekit.apiSecret;
        livekitUrl = dbSetting?.livekitUrl || config.livekit.url;
      } catch (_) {
        apiKey = config.livekit.apiKey;
        apiSecret = config.livekit.apiSecret;
        livekitUrl = config.livekit.url;
      }

      const { EgressClient } = await import('livekit-server-sdk');
      const host = livekitUrl.replace(/^wss:\/\//, 'https://').replace(/^ws:\/\//, 'http://');
      const egressClient = new EgressClient(host, apiKey, apiSecret);

      // Poll for up to 30 seconds
      for (let attempt = 0; attempt < 6; attempt++) {
        await new Promise(r => setTimeout(r, 5000));
        try {
          const egressList = await egressClient.listEgress({ egressId: meeting.egressId });
          const egress = egressList[0];
          if (egress?.fileResults && egress.fileResults.length > 0) {
            const fileLocation = egress.fileResults[0].location || '';
            const fileSize = Number(egress.fileResults[0].size || 0);
            if (fileLocation) {
              meeting.recordingUrl = fileLocation;
              const recordingStart = egress.startedAt
                ? new Date(Number(egress.startedAt) / 1000000).toISOString()
                : (meeting.createdAt?.toISOString() || new Date().toISOString());
              const recordingEnd = egress.endedAt
                ? new Date(Number(egress.endedAt) / 1000000).toISOString()
                : new Date().toISOString();
              meeting.recordings = [{
                id: meeting.egressId!,
                fileType: 'mp4',
                fileExtension: 'mp4',
                fileSize,
                playUrl: fileLocation,
                downloadUrl: fileLocation,
                recordingType: 'livekit_egress',
                recordingStart,
                recordingEnd,
              }];
              debug(`[Meeting] ✅ Recording S3 URL captured: ${fileLocation}`);
              // Auto-save to Evidence Vault
              autoSaveMeetingToVault(meeting, fileLocation, fileSize).catch(() => {});
              break;
            }
          }
          // EgressStatus: 0=EGRESS_STARTING, 1=EGRESS_ACTIVE, 2=EGRESS_ENDING, 3=EGRESS_COMPLETE, 4=EGRESS_ABORTED, 5=EGRESS_FAILED
          const status = Number(egress?.status ?? -1);
          if (status >= 3) break; // COMPLETE, ABORTED, or FAILED — stop polling
        } catch (pollErr) {
          debugError('[Meeting] Egress poll error:', pollErr instanceof Error ? pollErr.message : String(pollErr));
          break;
        }
      }
    } catch (err) {
      debugError('[Meeting] Error stopping LiveKit egress on meeting end:', (err as Error)?.message || err);
    }
  }

  await meeting.save();

  // Close the LiveKit room so all active participants are disconnected and no one can join
  try {
    let dbSetting, apiKey, apiSecret, livekitUrl;
    try {
      dbSetting = await import('../storageSetting/storageSetting.model').then(m => m.StorageSetting.findOne().sort({ updatedAt: -1 }));
      apiKey = dbSetting?.livekitApiKey || config.livekit.apiKey;
      apiSecret = dbSetting?.livekitApiSecret || config.livekit.apiSecret;
      livekitUrl = dbSetting?.livekitUrl || config.livekit.url;
    } catch (_) {
      apiKey = config.livekit.apiKey;
      apiSecret = config.livekit.apiSecret;
      livekitUrl = config.livekit.url;
    }

    const { RoomServiceClient } = await import('livekit-server-sdk');
    const host = livekitUrl.replace(/^wss:\/\//, 'https://').replace(/^ws:\/\//, 'http://');
    const roomService = new RoomServiceClient(host, apiKey, apiSecret);
    const roomName = meeting.roomName || meeting.sessionName || `govia_${meeting._id}`;
    await roomService.deleteRoom(roomName);
    debug(`[Meeting] ✅ Closed LiveKit room "${roomName}" so no one can join.`);
  } catch (err) {
    debugError('[Meeting] Error deleting LiveKit room on end:', (err as Error)?.message || err);
  }

  await Message.updateMany(
    { meetingId: meeting._id },
    {
      text: `🏁 Meeting Ended: ${meeting.topic}${meeting.recordingUrl ? '\n📹 Recording is available' : ''}`,
    }
  );

  const populatedMeeting = await Meeting.findById(meeting._id)
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('joinedAttorneys', 'name email role image')
    .populate('conversationId');

  // Emit real-time socket events so both in chat and schedule list, "Join Now" is replaced by recording
  if (meeting.conversationId) {
    socketHelper.emitToConversation(
      meeting.conversationId.toString(),
      'meeting_ended',
      populatedMeeting
    );
    if (meeting.recordingUrl) {
      socketHelper.emitToConversation(
        meeting.conversationId.toString(),
        'meeting_recording_ready',
        { meetingId: meeting._id, recordingUrl: meeting.recordingUrl }
      );
    }
  }

  socketHelper.emitToUser(
    meeting.userId.toString(),
    'meeting_ended',
    populatedMeeting
  );

  if (meeting.participantId) {
    socketHelper.emitToUser(
      meeting.participantId.toString(),
      'meeting_ended',
      populatedMeeting
    );
  }

  // If the host ends the call, mark ANY other orphan ACTIVE meetings for this host as COMPLETED
  if (isHost) {
    await Meeting.updateMany(
      { userId: userObjectId, status: 'ACTIVE' },
      { status: 'COMPLETED', endedAt: new Date() }
    );
  }

  // Broadcast to all participants on all platforms so the call ends everywhere
  socketHelper.broadcast('meeting_ended', {
    meetingId: meeting._id.toString(),
    sessionName: meeting.sessionName || meeting.roomName,
  });

  socketHelper.broadcast('emergency_meeting_ended', {
    meetingId: meeting._id.toString(),
  });

  socketHelper.broadcast('active_meetings_updated', {
    meetingId: meeting._id.toString(),
  });

  return populatedMeeting;
};



const cancelMeeting = async (userId: string, meetingId: string) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  const userObjectId = new Types.ObjectId(userId);
  const isHost = meeting.userId.equals(userObjectId);
  const isParticipant =
    meeting.participantId && meeting.participantId.equals(userObjectId);

  if (!isHost && !isParticipant) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You do not have permission to cancel this meeting'
    );
  }

  meeting.status = 'CANCELLED';
  await meeting.save();

  // Notify counterparty
  const targetUserId = isHost
    ? meeting.participantId?.toString()
    : meeting.userId.toString();
  if (targetUserId) {
    socketHelper.emitToUser(targetUserId, 'meeting_cancelled', {
      meetingId: meeting._id,
      cancelledBy: userId,
    });
  }

  return meeting;
};

const getMeetingRecordings = async (meetingId: string, userId?: string) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  if (userId) {
    const user = await User.findById(userId);
    const isCitizen =
      user?.role === USER_ROLES.CITIZEN || user?.role === USER_ROLES.USER;
    if (isCitizen) {
      const subStatus = await SubscriptionService.getUserSubscriptionStatus(
        userId,
        user?.role
      );
      if (!subStatus.features.canViewRecordings) {
        throw new ApiError(
          StatusCodes.FORBIDDEN,
          'Cloud recordings and video playback require Govia Premium. Please upgrade your subscription.'
        );
      }
    }
  }

  return {
    share_url: meeting.recordingUrl || '',
    recording_files: meeting.recordings || [],
  };
};

const syncMeetingRecordings = async (meetingId: string, userId?: string) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

  if (userId) {
    const user = await User.findById(userId);
    const isCitizen =
      user?.role === USER_ROLES.CITIZEN || user?.role === USER_ROLES.USER;
    if (isCitizen) {
      const subStatus = await SubscriptionService.getUserSubscriptionStatus(
        userId,
        user?.role
      );
      if (!subStatus.features.canViewRecordings) {
        throw new ApiError(
          StatusCodes.FORBIDDEN,
          'Cloud recordings and video playback require Govia Premium. Please upgrade your subscription.'
        );
      }
    }
  }

  return {
    meeting,
    recordings: {
      share_url: meeting?.recordingUrl || '',
      recording_files: meeting?.recordings || [],
    },
  };
};

const getAttorneyRecordings = async (attorneyId: string) => {
  const meetings = await Meeting.find({
    joinedAttorneys: new Types.ObjectId(attorneyId),
  });

  return meetings.map(m => ({
    meeting: m,
    recordings: {
      share_url: m.recordingUrl || '',
      recording_files: m.recordings || [],
    },
  }));
};

const getMeetingSdkToken = async (meetingId: string, userId: string) => {
  if (!Types.ObjectId.isValid(meetingId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid meeting ID');
  }

  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  // Reject token request if meeting has ended
  if (
    meeting.status === 'COMPLETED' ||
    meeting.status === 'CANCELLED' ||
    meeting.endedAt
  ) {
    throw new ApiError(
      StatusCodes.GONE,
      'This meeting has ended and is no longer available to join.'
    );
  }

  const user = await User.findById(userId);
  const userObjectId = new Types.ObjectId(userId);
  const isHost = meeting.userId.equals(userObjectId);
  const roomName = meeting.roomName || meeting.sessionName || `govia_${meeting._id}`;

  const livekitToken = await createLiveKitToken({
    roomName,
    participantIdentity: userId,
    participantName: user?.name || (isHost ? 'Host' : 'Participant'),
  });

  return {
    meetingId: meeting._id,
    sessionName: roomName,
    roomName,
    isHost,
    token: livekitToken,
    livekitToken,
    livekitUrl: config.livekit.url,
  };
};

/**
 * Helper to auto-save or update meeting recording into the user's Evidence Vault
 */
const autoSaveMeetingToVault = async (
  meeting: Partial<IMeeting> & { _id?: unknown },
  fileUrl: string,
  fileSize = 0
) => {
  try {
    if (!meeting || !meeting.userId || !fileUrl) return;

    let folder = await VaultFolder.findOne({
      userId: meeting.userId,
      $or: [
        { name: meeting.topic },
        { category: meeting.category || 'ENCOUNTER' },
      ],
      isArchived: false,
    });

    if (!folder) {
      folder = await VaultFolder.create({
        userId: meeting.userId,
        name: meeting.topic || 'Recorded Incident',
        description: `Encounter & meeting recording for ${meeting.topic}`,
        category: meeting.category || 'ENCOUNTER',
        incidentDate: meeting.createdAt || new Date(),
        location: meeting.locationAddress || '',
      });
    }

    const existingItem = await VaultItem.findOne({ meetingId: meeting._id });
    if (!existingItem) {
      await VaultItem.create({
        userId: meeting.userId,
        folderId: folder._id,
        title: `${meeting.topic} - Video Recording`,
        description: `Official recorded evidence for session: ${meeting.topic}`,
        category: meeting.category || 'ENCOUNTER',
        importance: meeting.meetingType === 'EMERGENCY' ? 'CRITICAL' : 'HIGH',
        fileType: 'RECORDING',
        fileUrl,
        fileSize,
        mimeType: 'video/mp4',
        meetingId: meeting._id,
      });
      debug(`[Vault] Created evidence vault item for meeting ${meeting._id}`);
    } else {
      existingItem.fileUrl = fileUrl;
      if (fileSize) existingItem.fileSize = fileSize;
      await existingItem.save();
    }
  } catch (err: unknown) {
    debugError(
      '[Vault] Failed to auto-save meeting recording to Vault:',
      err instanceof Error ? err.message : String(err)
    );
  }
};

const startRecording = async (meetingId: string, _userId?: string) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  // If egress is already running for this meeting, return existing info
  if (meeting.egressId) {
    return {
      success: true,
      meetingId: meeting._id,
      egressId: meeting.egressId,
      recordingActive: true,
      message: 'Recording is already active for this meeting',
    };
  }

  // Trigger LiveKit Egress room composite recording if S3 storage is configured
  const egressInfo = await startLiveKitRecording(meeting.roomName);
  if (egressInfo?.egressId) {
    meeting.egressId = String(egressInfo.egressId);
    await meeting.save();
    debug(
      `[Meeting] Saved egressId ${meeting.egressId} for meeting ${meeting._id}`
    );
  }

  // Notify active participants via socket that meeting recording is active
  if (meeting.conversationId) {
    socketHelper.emitToConversation(
      meeting.conversationId.toString(),
      'meeting_recording_started',
      { meetingId: meeting._id, egressId: meeting.egressId }
    );
  }

  return {
    success: true,
    meetingId: meeting._id,
    egressId: meeting.egressId || '',
    recordingActive: true,
    cloudEgress: Boolean(egressInfo?.egressId),
  };
};

const stopRecording = async (meetingId: string, _userId?: string) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  if (meeting.egressId) {
    await stopLiveKitRecording(meeting.egressId);
  }

  return {
    success: true,
    meetingId: meeting._id,
    recordingActive: false,
    message:
      'Stop recording initiated. The video will be processed and attached shortly.',
  };
};

const handleLiveKitWebhook = async (
  rawBody: string,
  authHeader?: string
) => {
  try {
    const event = await verifyLiveKitWebhook(rawBody, authHeader);
    debug(`[LiveKit Webhook] Event received: ${event.event}`);

    if (event.event === 'egress_ended' || event.event === 'egress_updated') {
      const egress = event.egressInfo;
      if (!egress) return { success: true };

      const roomName = egress.roomName;
      const egressId = egress.egressId;

      const meeting = await Meeting.findOne({
        $or: [
          { egressId: egressId },
          { roomName: roomName },
          { sessionName: roomName },
        ],
      });

      if (!meeting) {
        debug(
          `[LiveKit Webhook] Meeting not found for egress ${egressId} room ${roomName}`
        );
        return { success: true };
      }

      let fileLocation = '';
      let fileSize = 0;

      if (egress.fileResults && egress.fileResults.length > 0) {
        const file = egress.fileResults[0];
        fileLocation = file.location || '';
        fileSize = Number(file.size || 0);
      }

      if (fileLocation) {
        meeting.recordingUrl = fileLocation;
        meeting.status = 'COMPLETED';
        meeting.endedAt = meeting.endedAt || new Date();

        const recordingStart = egress.startedAt
          ? new Date(Number(egress.startedAt) / 1000000).toISOString()
          : new Date().toISOString();
        const recordingEnd = egress.endedAt
          ? new Date(Number(egress.endedAt) / 1000000).toISOString()
          : new Date().toISOString();

        meeting.recordings = [
          {
            id: egressId,
            fileType: 'mp4',
            fileExtension: 'mp4',
            fileSize,
            playUrl: fileLocation,
            downloadUrl: fileLocation,
            recordingType: 'livekit_egress',
            recordingStart,
            recordingEnd,
          },
        ];

        await meeting.save();

        // Update chat messages
        await Message.updateMany(
          { meetingId: meeting._id },
          {
            text: `🏁 Meeting Ended: ${meeting.topic}\n📹 Recording is available`,
          }
        );

        // Auto-save into Evidence Vault
        await autoSaveMeetingToVault(meeting, fileLocation, fileSize);

        // Real-time socket broadcast
        const populatedMeeting = await Meeting.findById(meeting._id)
          .populate('userId', 'name email role image phoneNumber')
          .populate('participantId', 'name email role image phoneNumber')
          .populate('joinedAttorneys', 'name email role image')
          .populate('conversationId');

        if (meeting.conversationId) {
          socketHelper.emitToConversation(
            meeting.conversationId.toString(),
            'meeting_ended',
            populatedMeeting
          );
          socketHelper.emitToConversation(
            meeting.conversationId.toString(),
            'meeting_recording_ready',
            { meetingId: meeting._id, recordingUrl: fileLocation }
          );
        }

        socketHelper.emitToUser(
          meeting.userId.toString(),
          'meeting_ended',
          populatedMeeting
        );
        if (meeting.participantId) {
          socketHelper.emitToUser(
            meeting.participantId.toString(),
            'meeting_ended',
            populatedMeeting
          );
        }

        debug(
          `[LiveKit Webhook] Attached recording ${fileLocation} to meeting ${meeting._id}`
        );
      }
    } else if (event.event === 'room_finished') {
      const room = event.room;
      if (room?.name) {
        const meeting = await Meeting.findOne({
          $or: [{ roomName: room.name }, { sessionName: room.name }],
          status: 'ACTIVE',
        });
        if (meeting) {
          meeting.status = 'COMPLETED';
          meeting.endedAt = new Date();
          await meeting.save();

          if (meeting.egressId) {
            stopLiveKitRecording(meeting.egressId).catch(() => {});
          }

          if (meeting.conversationId) {
            socketHelper.emitToConversation(
              meeting.conversationId.toString(),
              'meeting_ended',
              meeting
            );
          }
        }
      }
    }

    return { success: true };
  } catch (error: unknown) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    debugError(
      '[LiveKit Webhook] Error processing webhook:',
      errorMsg
    );
    return { success: false, error: errorMsg };
  }
};

const uploadRecordingDirect = async (
  meetingId: string,
  filePath: string,
  fileSize = 0,
  _userId?: string
) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  meeting.recordingUrl = filePath;
  meeting.status = 'COMPLETED';
  meeting.endedAt = new Date();
  meeting.recordings = [
    {
      id: `upload_${Date.now()}`,
      fileType: 'mp4',
      fileExtension: 'mp4',
      fileSize,
      playUrl: filePath,
      downloadUrl: filePath,
      recordingType: 'direct_upload',
      recordingStart:
        meeting.createdAt?.toISOString() || new Date().toISOString(),
      recordingEnd: new Date().toISOString(),
    },
  ];

  await meeting.save();

  await Message.updateMany(
    { meetingId: meeting._id },
    {
      text: `🏁 Meeting Ended: ${meeting.topic}\n📹 Recording is available`,
    }
  );

  await autoSaveMeetingToVault(meeting, filePath, fileSize);

  const populatedMeeting = await Meeting.findById(meeting._id)
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('joinedAttorneys', 'name email role image')
    .populate('conversationId');

  if (meeting.conversationId) {
    socketHelper.emitToConversation(
      meeting.conversationId.toString(),
      'meeting_ended',
      populatedMeeting
    );
    socketHelper.emitToConversation(
      meeting.conversationId.toString(),
      'meeting_recording_ready',
      { meetingId: meeting._id, recordingUrl: filePath }
    );
  }

  return populatedMeeting || meeting;
};

const attachRecording = async (
  meetingId: string,
  recordingUrl: string,
  userId?: string
) => {
  if (!recordingUrl) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'recordingUrl is required');
  }
  return await uploadRecordingDirect(meetingId, recordingUrl, 0, userId);
};

const getAllMeetingsForAdmin = async (
  query: {
    page?: number | string;
    limit?: number | string;
    status?: string;
    category?: string;
    searchTerm?: string;
  } = {}
) => {
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
  const skip = (page - 1) * limit;

  const filter: Record<string, unknown> = {};
  if (query.status) filter.status = query.status;
  if (query.category) filter.category = query.category;

  const meetings = await Meeting.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('joinedAttorneys', 'name email')
    .populate('joinedParticipants', 'name email role');

  const total = await Meeting.countDocuments(filter);

  return {
    meta: {
      page,
      limit,
      total,
      totalPage: Math.ceil(total / limit),
    },
    data: meetings,
  };
};

export const MeetingService = {
  createInstantMeeting,
  scheduleMeeting,
  updateMeeting,
  deleteMeeting,
  getActiveMeetings,
  getAllMeetingsForAdmin,
  getUserMeetings,
  joinMeeting,
  endMeeting,
  cancelMeeting,
  leaveMeeting,
  hostLeaveMeeting,
  hostRejoinedMeeting,
  getMeetingRecordings,
  syncMeetingRecordings,
  getAttorneyRecordings,
  getMeetingSdkToken,
  startRecording,
  stopRecording,
  handleLiveKitWebhook,
  uploadRecordingDirect,
  attachRecording,
};
