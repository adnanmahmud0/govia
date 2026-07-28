import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { MeetingService } from './meeting.service';

const startGovia = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await MeetingService.createZoomMeeting(userId, 'Govia Consultation');

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting created successfully',
    data: result,
  });
});

const emergencyCall = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await MeetingService.createZoomMeeting(userId, 'Emergency Protocol - I feel unsafe');

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Emergency meeting created successfully',
    data: result,
  });
});

const getRecordings = catchAsync(async (req: Request, res: Response) => {
  const { meetingId } = req.params;
  const result = await MeetingService.getMeetingRecordings(meetingId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting recordings retrieved successfully',
    data: result,
  });
});

const getActiveMeetings = catchAsync(async (req: Request, res: Response) => {
  const result = await MeetingService.getActiveMeetings();

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Active meetings retrieved successfully',
    data: result,
  });
});

const joinMeeting = catchAsync(async (req: Request, res: Response) => {
  const attorneyId = req.user?.id;
  const { meetingId } = req.params;
  const result = await MeetingService.joinMeeting(meetingId, attorneyId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Joined meeting successfully',
    data: result,
  });
});

const getAttorneyRecordings = catchAsync(async (req: Request, res: Response) => {
  const attorneyId = req.user?.id;
  const result = await MeetingService.getAttorneyRecordings(attorneyId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Attorney recordings retrieved successfully',
    data: result,
  });
});

export const MeetingController = {
  startGovia,
  emergencyCall,
  getRecordings,
  getActiveMeetings,
  joinMeeting,
  getAttorneyRecordings,
};
