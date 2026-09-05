import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { MeetingService } from './meeting.service';

const startGovia = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { topic = 'Govia Consultation', participantId, conversationId } = req.body;

  const result = await MeetingService.createInstantMeeting(
    userId,
    topic,
    participantId,
    false,
    conversationId
  );

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Instant meeting created successfully',
    data: result,
  });
});

const emergencyCall = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await MeetingService.createInstantMeeting(
    userId,
    'Emergency Protocol - I feel unsafe',
    undefined,
    true
  );

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Emergency meeting created successfully',
    data: result,
  });
});

const scheduleMeeting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await MeetingService.scheduleMeeting(userId, req.body);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.CREATED,
    message: 'Meeting scheduled successfully',
    data: result,
  });
});

const getMyMeetings = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await MeetingService.getUserMeetings(userId, req.query);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'User meetings retrieved successfully',
    data: result,
  });
});

const endMeeting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.endMeeting(userId, id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting ended successfully and recordings fetched',
    data: result,
  });
});

const syncRecording = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const result = await MeetingService.syncMeetingRecordings(id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting recordings synchronized successfully',
    data: result,
  });
});

const cancelMeeting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.cancelMeeting(userId, id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting cancelled successfully',
    data: result,
  });
});

const getRecordings = catchAsync(async (req: Request, res: Response) => {
  const { meetingId } = req.params;
  const result = await MeetingService.syncMeetingRecordings(meetingId);

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

const getAttorneyRecordings = catchAsync(
  async (req: Request, res: Response) => {
    const attorneyId = req.user?.id;
    const result = await MeetingService.getAttorneyRecordings(attorneyId);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'Attorney recordings retrieved successfully',
      data: result,
    });
  }
);

export const MeetingController = {
  startGovia,
  emergencyCall,
  scheduleMeeting,
  getMyMeetings,
  endMeeting,
  syncRecording,
  cancelMeeting,
  getRecordings,
  getActiveMeetings,
  joinMeeting,
  getAttorneyRecordings,
};

