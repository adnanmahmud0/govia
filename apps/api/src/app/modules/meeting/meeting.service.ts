import { StatusCodes } from 'http-status-codes';
import { Types } from 'mongoose';
import config from '../../../config';
import ApiError from '../../../errors/ApiError';
import { socketHelper } from '../../../helpers/socketHelper';
import { User } from '../user/user.model';
import { Meeting } from './meeting.model';
import { Conversation } from '../conversation/conversation.model';
import { Message } from '../message/message.model';

type ZoomRecordingApiFile = {
  id?: string;
  file_type?: string;
  file_extension?: string;
  file_size?: number;
  play_url?: string;
  download_url?: string;
  recording_type?: string;
  recording_start?: string;
  recording_end?: string;
};

type ZoomRecordingApiResponse = {
  share_url?: string;
  recording_files?: ZoomRecordingApiFile[];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  [key: string]: any;
};

const getZoomAccessToken = async () => {
  const { accountId, clientId, clientSecret } = config.zoom;

  if (!accountId || !clientId || !clientSecret) {
    throw new ApiError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      'Zoom credentials are not configured properly'
    );
  }

  const tokenUrl = `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${accountId}`;
  const authHeader = Buffer.from(`${clientId}:${clientSecret}`).toString(
    'base64'
  );

  try {
    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${authHeader}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    if (!response.ok) {
      const errorData = await response.text();
      console.error('Zoom token error:', errorData);
      throw new ApiError(
        StatusCodes.INTERNAL_SERVER_ERROR,
        `Failed to get Zoom access token: ${errorData}`
      );
    }

    const data = (await response.json()) as { access_token: string };
    return data.access_token;
  } catch (error: unknown) {
    console.error('Catch error in getZoomAccessToken:', error);
    if (error instanceof ApiError) throw error;
    throw new ApiError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      'Error communicating with Zoom API'
    );
  }
};

const createInstantMeeting = async (
  userId: string,
  topic = 'Instant Govia Consultation',
  participantId?: string,
  isEmergency = false,
  conversationId?: string
) => {
  const accessToken = await getZoomAccessToken();
  const meetingUrl = 'https://api.zoom.us/v2/users/me/meetings';

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

  try {
    const response = await fetch(meetingUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        topic,
        type: 1, // Instant meeting
        settings: {
          host_video: true,
          participant_video: true,
          join_before_host: false,
          mute_upon_entry: true,
          auto_recording: 'cloud',
        },
      }),
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new ApiError(
        StatusCodes.INTERNAL_SERVER_ERROR,
        `Failed to create Zoom meeting: ${errorData}`
      );
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const data = (await response.json()) as any;

    const newMeeting = await Meeting.create({
      userId: new Types.ObjectId(userId),
      participantId: participantObjectId,
      conversationId: convObjectId,
      zoomMeetingId: data.id.toString(),
      topic,
      joinUrl: data.join_url,
      startUrl: data.start_url,
      password: data.password,
      meetingType: isEmergency ? 'EMERGENCY' : 'INSTANT',
      status: 'ACTIVE',
    });

    const populatedMeeting = await Meeting.findById(newMeeting._id)
      .populate('userId', 'name email role image phoneNumber')
      .populate('participantId', 'name email role image phoneNumber')
      .populate('conversationId');

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
      socketHelper.emitToRole('ATTORNEY', 'emergency_alert', populatedMeeting);
      socketHelper.broadcast('emergency_meeting_created', populatedMeeting);
    } else if (participantId) {
      socketHelper.emitToUser(
        participantId,
        'instant_meeting_invite',
        populatedMeeting
      );
    }

    return populatedMeeting;
  } catch (error: unknown) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      'Error creating Zoom meeting'
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

  const accessToken = await getZoomAccessToken();
  const meetingUrl = 'https://api.zoom.us/v2/users/me/meetings';

  try {
    const response = await fetch(meetingUrl, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        topic,
        type: 2, // Scheduled meeting
        start_time: meetingDate.toISOString(),
        duration: durationMinutes,
        timezone,
        agenda: agenda || topic,
        settings: {
          host_video: true,
          participant_video: true,
          join_before_host: false,
          mute_upon_entry: true,
          auto_recording: 'cloud',
        },
      }),
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new ApiError(
        StatusCodes.INTERNAL_SERVER_ERROR,
        `Failed to schedule Zoom meeting: ${errorData}`
      );
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const data = (await response.json()) as any;

    const scheduledMeeting = await Meeting.create({
      userId: new Types.ObjectId(userId),
      participantId: participantObjectId,
      conversationId: convObjectId,
      zoomMeetingId: data.id.toString(),
      topic,
      joinUrl: data.join_url,
      startUrl: data.start_url,
      password: data.password,
      meetingType: 'SCHEDULED',
      startTime: meetingDate,
      durationMinutes,
      timezone,
      agenda,
      status: 'SCHEDULED',
    });

    const populatedMeeting = await Meeting.findById(scheduledMeeting._id)
      .populate('userId', 'name email role image phoneNumber')
      .populate('participantId', 'name email role image phoneNumber')
      .populate('conversationId');

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
        populatedMeeting
      );
    }

    return populatedMeeting;
  } catch (error: unknown) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      'Error scheduling Zoom meeting'
    );
  }
};

const getActiveMeetings = async () => {
  const activeMeetings = await Meeting.find({ status: 'ACTIVE' })
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('conversationId');
  return activeMeetings;
};

const getUserMeetings = async (
  userId: string,
  query: {
    status?: string;
    meetingType?: string;
    timeFilter?: string;
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
    ],
  };

  if (query.status) {
    filter.status = query.status;
  }

  if (query.meetingType) {
    filter.meetingType = query.meetingType;
  }

  if (query.timeFilter === 'upcoming') {
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

const joinMeeting = async (meetingId: string, attorneyId: string) => {
  const meeting = await Meeting.findById(meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting not found');
  }

  const objAttorneyId = new Types.ObjectId(attorneyId);
  if (!meeting.joinedAttorneys.some(id => id.equals(objAttorneyId))) {
    meeting.joinedAttorneys.push(objAttorneyId);
    await meeting.save();
  }

  socketHelper.emitToUser(meeting.userId.toString(), 'meeting_joined', {
    meetingId: meeting._id,
    attorneyId,
  });

  return { joinUrl: meeting.joinUrl };
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
  const isJoinedAttorney = meeting.joinedAttorneys.some(id =>
    id.equals(userObjectId)
  );

  if (!isHost && !isParticipant && !isJoinedAttorney) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You do not have permission to end this meeting'
    );
  }

  meeting.status = 'COMPLETED';
  meeting.endedAt = new Date();

  // Try to query Zoom recordings immediately
  try {
    const recordingData = await getMeetingRecordings(meeting.zoomMeetingId);
    if (recordingData) {
      if (recordingData.share_url) {
        meeting.recordingUrl = recordingData.share_url;
      }
      if (
        Array.isArray(recordingData.recording_files) &&
        recordingData.recording_files.length > 0
      ) {
        meeting.recordings = recordingData.recording_files.map(
          (file: ZoomRecordingApiFile) => ({
          id: file.id,
          fileType: file.file_type,
          fileExtension: file.file_extension,
          fileSize: file.file_size,
          playUrl: file.play_url,
          downloadUrl: file.download_url,
          recordingType: file.recording_type,
          recordingStart: file.recording_start,
          recordingEnd: file.recording_end,
        }));
        if (
          !meeting.recordingUrl &&
          recordingData.recording_files[0]?.play_url
        ) {
          meeting.recordingUrl = recordingData.recording_files[0].play_url;
        }
      }
    }
  } catch (zoomErr) {
    console.log('Zoom recordings processing or not ready yet:', zoomErr);
  }

  await meeting.save();

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

const getMeetingRecordings = async (zoomMeetingId: string) => {
  const accessToken = await getZoomAccessToken();
  const url = `https://api.zoom.us/v2/meetings/${zoomMeetingId}/recordings`;

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new ApiError(
        StatusCodes.INTERNAL_SERVER_ERROR,
        `Failed to fetch Zoom meeting recordings: ${errorData}`
      );
    }

    const data = (await response.json()) as ZoomRecordingApiResponse;
    return data;
  } catch (error: unknown) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(
      StatusCodes.INTERNAL_SERVER_ERROR,
      'Error fetching Zoom meeting recordings'
    );
  }
};

const syncMeetingRecordings = async (meetingId: string) => {
  let zoomMeetingId = meetingId;
  let meetingDoc = null;

  if (Types.ObjectId.isValid(meetingId)) {
    meetingDoc = await Meeting.findById(meetingId);
    if (meetingDoc) {
      zoomMeetingId = meetingDoc.zoomMeetingId;
    }
  }

  const recordingData = await getMeetingRecordings(zoomMeetingId);

  if (meetingDoc && recordingData) {
    if (recordingData.share_url) {
      meetingDoc.recordingUrl = recordingData.share_url;
    }
    if (
      Array.isArray(recordingData.recording_files) &&
      recordingData.recording_files.length > 0
    ) {
      meetingDoc.recordings = recordingData.recording_files.map(
        (file: ZoomRecordingApiFile) => ({
        id: file.id,
        fileType: file.file_type,
        fileExtension: file.file_extension,
        fileSize: file.file_size,
        playUrl: file.play_url,
        downloadUrl: file.download_url,
        recordingType: file.recording_type,
        recordingStart: file.recording_start,
        recordingEnd: file.recording_end,
      }));
      if (
        !meetingDoc.recordingUrl &&
        recordingData.recording_files[0]?.play_url
      ) {
        meetingDoc.recordingUrl = recordingData.recording_files[0].play_url;
      }
    }
    await meetingDoc.save();

    if (meetingDoc.conversationId) {
      socketHelper.emitToConversation(
        meetingDoc.conversationId.toString(),
        'meeting_updated',
        meetingDoc
      );
    }
  }

  return {
    meeting: meetingDoc,
    recordings: recordingData,
  };
};

const getAttorneyRecordings = async (attorneyId: string) => {
  const meetings = await Meeting.find({
    joinedAttorneys: new Types.ObjectId(attorneyId),
  });

  const results = [];
  for (const m of meetings) {
    try {
      const recordings = await getMeetingRecordings(m.zoomMeetingId);
      results.push({
        meeting: m,
        recordings,
      });
    } catch {
      results.push({
        meeting: m,
        recordings: null,
        error: 'Failed to fetch recordings',
      });
    }
  }

  return results;
};

export const MeetingService = {
  createInstantMeeting,
  scheduleMeeting,
  getActiveMeetings,
  getUserMeetings,
  joinMeeting,
  endMeeting,
  cancelMeeting,
  getMeetingRecordings,
  syncMeetingRecordings,
  getAttorneyRecordings,
};
