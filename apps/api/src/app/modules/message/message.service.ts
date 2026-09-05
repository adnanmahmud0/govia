import { StatusCodes } from 'http-status-codes';
import { Types } from 'mongoose';
import ApiError from '../../../errors/ApiError';
import { socketHelper } from '../../../helpers/socketHelper';
import { User } from '../user/user.model';
import { Conversation } from '../conversation/conversation.model';
import { IMessage } from './message.interface';
import { Message } from './message.model';

const sendMessage = async (
  senderId: string,
  payload: {
    conversationId: string;
    text?: string;
    attachment?: string;
    messageType?: 'text' | 'image' | 'file' | 'meeting';
    meetingId?: string;
  }
) => {
  const { conversationId, text, attachment, messageType, meetingId } = payload;

  const trimmedText = text?.trim();
  if (!trimmedText && !attachment && !meetingId) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      'Message must contain text, an attachment, or a meeting invitation'
    );
  }

  if (!Types.ObjectId.isValid(conversationId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid conversation ID format');
  }

  const conversation = await Conversation.findById(conversationId);
  if (!conversation) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Conversation not found');
  }

  const senderObjectId = new Types.ObjectId(senderId);
  const isParticipant = conversation.participants.some(p =>
    p.equals(senderObjectId)
  );

  if (!isParticipant) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You are not a participant in this conversation'
    );
  }

  // Determine receiver from participants
  const receiverObjectId = conversation.participants.find(
    p => !p.equals(senderObjectId)
  );

  if (!receiverObjectId) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      'No recipient found for this conversation'
    );
  }

  const resolvedMessageType =
    messageType ||
    (meetingId ? 'meeting' : attachment ? 'image' : 'text');

  const newMessagePayload: Partial<IMessage> = {
    conversationId: new Types.ObjectId(conversationId),
    sender: senderObjectId,
    receiver: receiverObjectId,
    text: trimmedText || '',
    attachment,
    messageType: resolvedMessageType,
    meetingId: meetingId ? new Types.ObjectId(meetingId) : undefined,
    read: false,
  };

  const message = await Message.create(newMessagePayload);

  // Update conversation last message snippet
  const lastMessageText =
    trimmedText ||
    (resolvedMessageType === 'meeting'
      ? '📅 Meeting Invitation'
      : resolvedMessageType === 'image'
      ? '📷 Image'
      : '📎 Attachment');

  const now = new Date();
  await Conversation.findByIdAndUpdate(conversationId, {
    lastMessage: message._id,
    lastMessageText,
    lastMessageAt: now,
  });

  const populatedMessage = await Message.findById(message._id)
    .populate('sender', 'name email role image phoneNumber')
    .populate('receiver', 'name email role image phoneNumber')
    .populate('meetingId');

  // Real-time socket emissions:
  // 1. Send new message directly to active conversation room
  socketHelper.emitToConversation(conversationId, 'new_message', populatedMessage);

  // 2. Count receiver unread messages to update their inbox badge without duplicate message renders
  const receiverUnreadCount = await Message.countDocuments({
    conversationId: new Types.ObjectId(conversationId),
    receiver: receiverObjectId,
    read: false,
  });

  // 3. Emit inbox_update to receiver's private room
  socketHelper.emitToUser(receiverObjectId.toString(), 'inbox_update', {
    conversationId,
    lastMessage: populatedMessage,
    lastMessageText,
    lastMessageAt: now,
    unreadCount: receiverUnreadCount,
  });

  return populatedMessage;
};

const getMessagesByConversation = async (
  userId: string,
  conversationId: string,
  page = 1,
  limit = 50
) => {
  if (!Types.ObjectId.isValid(conversationId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid conversation ID format');
  }

  const conversation = await Conversation.findById(conversationId);
  if (!conversation) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Conversation not found');
  }

  const userObjectId = new Types.ObjectId(userId);
  const isParticipant = conversation.participants.some(p =>
    p.equals(userObjectId)
  );

  if (!isParticipant) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You are not a participant in this conversation'
    );
  }

  const skip = (page - 1) * limit;

  // Retrieve newest messages first so Page 1 returns the latest messages
  const messages = await Message.find({
    conversationId: new Types.ObjectId(conversationId),
  })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate('sender', 'name email role image')
    .populate('receiver', 'name email role image')
    .populate('meetingId')
    .lean();

  const total = await Message.countDocuments({
    conversationId: new Types.ObjectId(conversationId),
  });

  // Reverse so the returned array is in chronological order for frontend display
  const chronologicalMessages = messages.reverse();

  return {
    meta: {
      page,
      limit,
      total,
      totalPage: Math.ceil(total / limit),
    },
    data: chronologicalMessages,
  };
};

const markMessagesAsRead = async (userId: string, conversationId: string) => {
  if (!Types.ObjectId.isValid(conversationId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid conversation ID format');
  }

  const conversation = await Conversation.findById(conversationId);
  if (!conversation) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Conversation not found');
  }

  const userObjectId = new Types.ObjectId(userId);
  const isParticipant = conversation.participants.some(p =>
    p.equals(userObjectId)
  );

  if (!isParticipant) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'You are not a participant in this conversation'
    );
  }

  const updateResult = await Message.updateMany(
    {
      conversationId: new Types.ObjectId(conversationId),
      receiver: userObjectId,
      read: false,
    },
    {
      $set: { read: true },
    }
  );

  socketHelper.emitToConversation(conversationId, 'messages_read', {
    conversationId,
    readerId: userId,
  });

  socketHelper.emitToUser(userId, 'inbox_update', {
    conversationId,
    unreadCount: 0,
  });

  return {
    message: 'Messages marked as read',
    modifiedCount: updateResult.modifiedCount,
  };
};

const searchUsersForMessaging = async (
  currentUserId: string,
  query: {
    searchTerm?: string;
    role?: string;
    page?: number | string;
    limit?: number | string;
  }
) => {
  const currentObjectId = new Types.ObjectId(currentUserId);
  const page = Number(query.page) || 1;
  const limit = Number(query.limit) || 20;
  const skip = (page - 1) * limit;

  const filter: Record<string, unknown> = {
    _id: { $ne: currentObjectId },
    status: 'active',
  };

  if (query.role) {
    filter.role = query.role;
  }

  if (query.searchTerm && query.searchTerm.trim()) {
    const searchRegex = new RegExp(query.searchTerm.trim(), 'i');
    filter.$or = [
      { name: searchRegex },
      { email: searchRegex },
      { role: searchRegex },
      { phoneNumber: searchRegex },
      { specialization: searchRegex },
      { lawFirmName: searchRegex },
      { officeName: searchRegex },
      { badgeNumber: searchRegex },
      { companyName: searchRegex },
    ];
  }

  const users = await User.find(filter)
    .select(
      '_id name email role image phoneNumber badgeNumber lawFirmName officeName specialization companyName'
    )
    .sort({ name: 1 })
    .skip(skip)
    .limit(limit)
    .lean();

  const total = await User.countDocuments(filter);

  if (!users.length) {
    return {
      meta: {
        page,
        limit,
        total,
        totalPage: Math.ceil(total / limit),
      },
      data: [],
    };
  }

  // Pre-calculate directKey for each user with current user to find existing conversations in one query
  const directKeys = users.map(u =>
    [currentUserId, u._id.toString()].sort().join('_')
  );

  const existingConversations = await Conversation.find({
    $or: [
      { directKey: { $in: directKeys } },
      { participants: currentObjectId },
    ],
  })
    .select('_id directKey participants')
    .lean();

  const conversationMap = new Map<string, string>();
  existingConversations.forEach(conv => {
    if (conv.directKey) {
      const parts = conv.directKey.split('_');
      const otherId = parts[0] === currentUserId ? parts[1] : parts[0];
      conversationMap.set(otherId, conv._id.toString());
    } else if (conv.participants && conv.participants.length === 2) {
      const otherParticipant = conv.participants.find(
        p => p.toString() !== currentUserId
      );
      if (otherParticipant) {
        conversationMap.set(otherParticipant.toString(), conv._id.toString());
      }
    }
  });

  const enrichedUsers = users.map(u => ({
    ...u,
    conversationId: conversationMap.get(u._id.toString()) || null,
  }));

  return {
    meta: {
      page,
      limit,
      total,
      totalPage: Math.ceil(total / limit),
    },
    data: enrichedUsers,
  };
};

export const MessageService = {
  sendMessage,
  getMessagesByConversation,
  markMessagesAsRead,
  searchUsersForMessaging,
};


