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

  try {
    const newMeeting = await Meeting.create({
      userId: new Types.ObjectId(userId),
      participantId: participantObjectId,
      conversationId: convObjectId,
      roomName,
      sessionName: roomName,
      topic,
      meetingType: isEmergency ? 'EMERGENCY' : 'INSTANT',
      status: 'ACTIVE',
    });

    const populatedMeeting = await Meeting.findById(newMeeting._id)
      .populate('userId', 'name email role image phoneNumber')
      .populate('participantId', 'name email role image phoneNumber')
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
  const activeMeetings = await Meeting.find({ status: 'ACTIVE' })
    .sort({ createdAt: -1 })
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

  const attorney = await User.findById(attorneyId);
  const roomName = meeting.roomName || meeting.sessionName || `govia_${meeting._id}`;
  const livekitToken = await createLiveKitToken({
    roomName,
    participantIdentity: attorneyId,
    participantName: attorney?.name || 'Attorney',
  });

  socketHelper.emitToUser(meeting.userId.toString(), 'meeting_joined', {
    meetingId: meeting._id,
    attorneyId,
  });

  return {
    meetingId: meeting._id,
    roomName,
    sessionName: roomName,
    token: livekitToken,
    livekitToken,
    livekitUrl: config.livekit.url,
    joinUrl: meeting.joinUrl,
  };
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
  getMeetingSdkToken,
};
