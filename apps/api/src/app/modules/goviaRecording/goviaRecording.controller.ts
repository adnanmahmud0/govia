import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { GoviaRecordingService } from './goviaRecording.service';

const createRecording = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await GoviaRecordingService.createRecording(userId, req.body);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Recording started/created successfully',
    data: result,
  });
});

const getRecordings = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await GoviaRecordingService.getRecordingsByUser(userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Recordings retrieved successfully',
    data: result,
  });
});

export const GoviaRecordingController = {
  createRecording,
  getRecordings,
};
