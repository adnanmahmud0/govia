import { StatusCodes } from 'http-status-codes';
import { Types } from 'mongoose';
import config from '../../../config';
import ApiError from '../../../errors/ApiError';
import { createLiveKitToken } from '../../../helpers/livekit.helper';
import { socketHelper } from '../../../helpers/socketHelper';
import { User } from '../user/user.model';
import { Meeting } from './meeting.model';
import { Conversation } from '../conversation/conversation.model';
import { Message } from '../message/message.model';
import { debug } from '../../../shared/debug';

const createInstantMeeting = async (
  userId: string,
  topic = 'Instant Govia Consultation',
  participantId?: string,
  isEmergency = false,
  conversationId?: string
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
    });

    const populatedMeeting = await Meeting.findById(newMeeting._id)
      .populate('userId', 'name email role image phoneNumber')
      .populate('participantId', 'name email role image phoneNumber')
      .populate('vaultFolderId', 'name description category')
      .populate('conversationId');

    const hostUser = await User.findById(userId);
    const livekitToken = await createLiveKitToken({
      roomName,
      participantIdentity: userId,
      participantName: hostUser?.name || 'Citizen',
    });

    const meetingResult: any = populatedMeeting
      ? populatedMeeting.toObject()
      : newMeeting.toObject();
    meetingResult.meetingId = newMeeting._id;
    meetingResult.sessionName = roomName;
    meetingResult.roomName = roomName;
    meetingResult.token = livekitToken;
    meetingResult.livekitToken = livekitToken;
    meetingResult.livekitUrl = config.livekit.url;

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

    // Real-time socket notification
    if (isEmergency) {
      socketHelper.emitToRole('ATTORNEY', 'emergency_alert', meetingResult);
      socketHelper.broadcast('emergency_meeting_created', meetingResult);
    } else if (participantId) {
      socketHelper.emitToUser(
        participantId,
        'instant_meeting_invite',
        meetingResult
      );
    } else {
      socketHelper.emitToRole('ATTORNEY', 'emergency_alert', meetingResult);
      socketHelper.broadcast('emergency_meeting_created', meetingResult);
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
    const uId = (m.userId as any)?._id?.toString() || m.userId?.toString();
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

  const meetings = await meetingQuery.lean();

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

  const user = await User.findById(userId);
  const userObjectId = new Types.ObjectId(userId);

  // If host joins / rejoins, cancel any pending 5-minute auto-end timer
  if (meeting.userId.toString() === userId) {
    hostRejoinedMeeting(meetingId, userId);
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

  const meetingData: any = populatedMeeting ? populatedMeeting.toObject() : meeting.toObject();

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

  await meeting.save();

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

  const userObjectId = new Types.ObjectId(userId);
  const isHost = meeting.userId.equals(userObjectId);
  const isParticipant =
    meeting.participantId && meeting.participantId.equals(userObjectId);

  if (!isHost && !isParticipant) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You do not have permission to delete this meeting'
    );
  }

  await Message.updateMany(
    { meetingId: meeting._id },
    { isDeleted: true, text: 'This meeting was deleted' }
  );

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

const hostRejoinedMeeting = (meetingId: string, userId: string) => {
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
  // Real recordings will be attached by LiveKit egress or cloud recording webhook
  await meeting.save();

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

const getMeetingRecordings = async (meetingId: string) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  return {
    share_url: meeting.recordingUrl || '',
    recording_files: meeting.recordings || [],
  };
};

const syncMeetingRecordings = async (meetingId: string) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

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

const startRecording = async (meetingId: string, userId?: string) => {
  const meeting = Types.ObjectId.isValid(meetingId)
    ? await Meeting.findById(meetingId)
    : await Meeting.findOne({ roomName: meetingId });

  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  // Best-effort recording trigger. If LiveKit Egress or cloud recording is configured, trigger here.
  return {
    success: true,
    meetingId: meeting._id,
    recordingActive: true,
  };
};

export const MeetingService = {
  createInstantMeeting,
  scheduleMeeting,
  updateMeeting,
  deleteMeeting,
  getActiveMeetings,
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
};
