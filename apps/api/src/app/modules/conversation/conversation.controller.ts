import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { ConversationService } from './conversation.service';
import { MessageService } from '../message/message.service';

const createOrGetConversation = catchAsync(
  async (req: Request, res: Response) => {
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
  }
);

const getUserConversations = catchAsync(async (req: Request, res: Response) => {
  const currentUserId = req.user.id;
  const page = req.query.page ? Number(req.query.page) : undefined;
  const limit = req.query.limit ? Number(req.query.limit) : undefined;

  const result = await ConversationService.getUserConversations(
    currentUserId,
    page,
    limit
  );

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Conversations retrieved successfully',
    data: result,
  });
});

const getSingleConversation = catchAsync(
  async (req: Request, res: Response) => {
    const currentUserId = req.user.id;
    const { id } = req.params;
    const result = await ConversationService.getSingleConversation(
      currentUserId,
      id
    );

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'Conversation retrieved successfully',
      data: result,
    });
  }
);

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

export const ConversationController = {
  createOrGetConversation,
  getUserConversations,
  getSingleConversation,
  searchUsersForMessaging,
};
