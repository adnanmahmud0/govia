import { StatusCodes } from 'http-status-codes';
import { Types } from 'mongoose';
import ApiError from '../../../errors/ApiError';
import { User } from '../user/user.model';
import { Conversation } from './conversation.model';
import { Message } from '../message/message.model';

const createOrGetConversation = async (
  currentUserId: string,
  participantId: string
) => {
  if (currentUserId === participantId) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      'Cannot start conversation with yourself'
    );
  }

  if (!Types.ObjectId.isValid(participantId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid participant ID format');
  }

  const participantUser = await User.findOne({
    _id: new Types.ObjectId(participantId),
    status: 'active',
  });

  if (!participantUser) {
    throw new ApiError(
      StatusCodes.NOT_FOUND,
      'Participant user not found or inactive'
    );
  }

  const user1 = new Types.ObjectId(currentUserId);
  const user2 = new Types.ObjectId(participantId);

  // Deterministic directKey prevents duplicate conversation race conditions
  const directKey = [currentUserId, participantId].sort().join('_');

  let conversation = await Conversation.findOne({
    $or: [
      { directKey },
      { participants: { $all: [user1, user2], $size: 2 } },
    ],
  })
    .populate(
      'participants',
      'name email role image phoneNumber badgeNumber lawFirmName officeName specialization'
    )
    .populate('lastMessage');

  if (!conversation) {
    try {
      conversation = await Conversation.create({
        participants: [user1, user2],
        directKey,
      });
    } catch (error: unknown) {
      // Handle concurrent race condition gracefully if directKey already created
      if ((error as { code?: number })?.code === 11000) {
        conversation = await Conversation.findOne({ directKey });
      } else {
        throw error;
      }
    }

    if (conversation) {
      conversation = await Conversation.findById(conversation._id)
        .populate(
          'participants',
          'name email role image phoneNumber badgeNumber lawFirmName officeName specialization'
        )
        .populate('lastMessage');
    }
  }

  const unreadCount = conversation
    ? await Message.countDocuments({
        conversationId: conversation._id,
        receiver: user1,
        read: false,
      })
    : 0;

  return conversation
    ? { ...conversation.toObject(), unreadCount }
    : null;
};

const getUserConversations = async (
  userId: string,
  page?: number,
  limit?: number
) => {
  const userObjectId = new Types.ObjectId(userId);
  const query = { participants: userObjectId };

  let conversationQuery = Conversation.find(query)
    .sort({ lastMessageAt: -1, updatedAt: -1 })
    .populate(
      'participants',
      'name email role image phoneNumber badgeNumber lawFirmName officeName specialization'
    )
    .populate('lastMessage');

  if (page && limit) {
    const skip = (page - 1) * limit;
    conversationQuery = conversationQuery.skip(skip).limit(limit);
  }

  const conversations = await conversationQuery.lean();

  if (!conversations.length) {
    return page && limit
      ? {
          meta: { page, limit, total: 0, totalPage: 0 },
          data: [],
        }
      : [];
  }

  // Aggregation batch lookup to compute unreadCount for each conversation
  const conversationIds = conversations.map(c => c._id);
  const unreadCounts = await Message.aggregate([
    {
      $match: {
        conversationId: { $in: conversationIds },
        receiver: userObjectId,
        read: false,
      },
    },
    {
      $group: {
        _id: '$conversationId',
        count: { $sum: 1 },
      },
    },
  ]);

  const countMap = new Map<string, number>();
  unreadCounts.forEach(item => {
    countMap.set(item._id.toString(), item.count);
  });

  const enrichedConversations = conversations.map(c => ({
    ...c,
    unreadCount: countMap.get(c._id.toString()) || 0,
  }));

  if (page && limit) {
    const total = await Conversation.countDocuments(query);
    return {
      meta: {
        page,
        limit,
        total,
        totalPage: Math.ceil(total / limit),
      },
      data: enrichedConversations,
    };
  }

  return enrichedConversations;
};

const getSingleConversation = async (
  userId: string,
  conversationId: string
) => {
  if (!Types.ObjectId.isValid(conversationId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid conversation ID format');
  }

  const userObjectId = new Types.ObjectId(userId);
  const conversation = await Conversation.findOne({
    _id: new Types.ObjectId(conversationId),
    participants: userObjectId,
  })
    .populate(
      'participants',
      'name email role image phoneNumber badgeNumber lawFirmName officeName specialization'
    )
    .populate('lastMessage')
    .lean();

  if (!conversation) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Conversation not found');
  }

  const unreadCount = await Message.countDocuments({
    conversationId: conversation._id,
    receiver: userObjectId,
    read: false,
  });

  return { ...conversation, unreadCount };
};

export const ConversationService = {
  createOrGetConversation,
  getUserConversations,
  getSingleConversation,
};

