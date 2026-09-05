import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import { getSingleFilePath } from '../../../shared/getFilePath';
import sendResponse from '../../../shared/sendResponse';
import ApiError from '../../../errors/ApiError';
import { ConversationService } from '../conversation/conversation.service';
import { MeetingService } from '../meeting/meeting.service';
import { MessageService } from './message.service';

type FileParam = Parameters<typeof getSingleFilePath>[0];

const sendMessage = catchAsync(async (req: Request, res: Response) => {
  const senderId = req.user.id;
  const files = req.files as FileParam;

  const imagePath = getSingleFilePath(files, 'image');
  const mediaPath = getSingleFilePath(files, 'media');
  const docPath = getSingleFilePath(files, 'doc');

  const attachment = imagePath || mediaPath || docPath;

  const payload = { ...req.body };

  if (attachment) {
    payload.attachment = attachment;
    if (!payload.messageType) {
      if (imagePath) {
        payload.messageType = 'image';
      } else {
        payload.messageType = 'file';
      }
    }
  }

  const result = await MessageService.sendMessage(senderId, payload);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.CREATED,
    message: 'Message sent successfully',
    data: result,
  });
});

const createMeetingInChat = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const {
    conversationId,
    topic,
    meetingType,
    startTime,
    durationMinutes,
    timezone,
    agenda,
  } = req.body;

  let result;
  if (meetingType === 'INSTANT') {
    result = await MeetingService.createInstantMeeting(
      userId,
      topic,
      undefined,
      false,
      conversationId
    );
  } else {
    if (!startTime) {
      throw new ApiError(
        StatusCodes.BAD_REQUEST,
        'startTime is required for SCHEDULED meetings'
      );
    }
    result = await MeetingService.scheduleMeeting(userId, {
      conversationId,
      topic,
      startTime,
      durationMinutes,
      timezone,
      agenda,
    });
  }

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.CREATED,
    message: `${meetingType === 'INSTANT' ? 'Instant' : 'Scheduled'} meeting created in chat successfully`,
    data: result,
  });
});

const getMessages = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const { conversationId } = req.params;
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 50;

  const result = await MessageService.getMessagesByConversation(
    userId,
    conversationId,
    page,
    limit
  );

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Messages retrieved successfully',
    data: result,
  });
});

const markAsRead = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const { conversationId } = req.params;

  const result = await MessageService.markMessagesAsRead(userId, conversationId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Messages marked as read successfully',
    data: result,
  });
});

const searchUsersForMessaging = catchAsync(
  async (req: Request, res: Response) => {
    const currentUserId = req.user.id;
    const result = await MessageService.searchUsersForMessaging(
      currentUserId,
      req.query
    );

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'Users retrieved successfully for messaging',
      data: result,
    });
  }
);

const openChat = catchAsync(async (req: Request, res: Response) => {
  const currentUserId = req.user.id;
  const { participantId } = req.body;

  const result = await ConversationService.createOrGetConversation(
    currentUserId,
    participantId
  );

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Conversation retrieved or created successfully',
    data: result,
  });
});

export const MessageController = {
  sendMessage,
  createMeetingInChat,
  getMessages,
  markAsRead,
  searchUsersForMessaging,
  openChat,
};

