import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { StorageSettingService } from './storageSetting.service';

const getStorageSetting = catchAsync(async (req: Request, res: Response) => {
  const result = await StorageSettingService.getStorageSetting();
  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Storage settings retrieved successfully',
    data: result,
  });
});

const saveStorageSetting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await StorageSettingService.saveStorageSetting(req.body, userId);
  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Storage settings saved and applied successfully',
    data: result,
  });
});

const testStorageConnection = catchAsync(async (req: Request, res: Response) => {
  const result = await StorageSettingService.testStorageConnection(req.body);
  sendResponse(res, {
    success: result.success,
    statusCode: result.success ? StatusCodes.OK : StatusCodes.BAD_REQUEST,
    message: result.message,
    data: (result as { details?: unknown }).details || null,
  });
});

const getAllRecordings = catchAsync(async (req: Request, res: Response) => {
  const result = await StorageSettingService.getAllRecordings(
    req.query as Record<string, string | undefined>
  );
  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'All recordings retrieved successfully',
    data: result,
  });
});

const deleteRecording = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const result = await StorageSettingService.deleteRecordingFromMeeting(id);
  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Recording removed from meeting successfully',
    data: result,
  });
});

export const StorageSettingController = {
  getStorageSetting,
  saveStorageSetting,
  testStorageConnection,
  getAllRecordings,
  deleteRecording,
};
