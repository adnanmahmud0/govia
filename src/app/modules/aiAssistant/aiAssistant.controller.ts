import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { AiAssistantService } from './aiAssistant.service';

const generateResponse = catchAsync(async (req: Request, res: Response) => {
  const { prompt, history, chatId } = req.body;
  const userId = req.user?.id; // Assuming auth middleware sets req.user
  
  const result = await AiAssistantService.generateResponse(userId, prompt, chatId, history);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'AI response generated successfully',
    data: result,
  });
});

const getChatList = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await AiAssistantService.getChatList(userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Chat list retrieved successfully',
    data: result,
  });
});

const getChatHistory = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await AiAssistantService.getChatHistory(userId, id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Chat history retrieved successfully',
    data: result,
  });
});

export const AiAssistantController = {
  generateResponse,
  getChatList,
  getChatHistory,
};
