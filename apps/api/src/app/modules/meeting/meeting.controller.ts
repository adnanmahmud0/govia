import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import ApiError from '../../../errors/ApiError';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { MeetingService } from './meeting.service';

const startGovia = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const {
    topic = 'Govia Consultation',
    participantId,
    conversationId,
    latitude,
    longitude,
    locationAddress,
  } = req.body;

  const result = await MeetingService.createInstantMeeting(
    userId,
    topic,
    participantId,
    false,
    conversationId,
    latitude !== undefined ? Number(latitude) : undefined,
    longitude !== undefined ? Number(longitude) : undefined,
    locationAddress
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
  const {
    topic = 'Emergency Incident Protocol',
    preferredAttorney,
    preferredBailBondsman,
    latitude,
    longitude,
    locationAddress,
  } = req.body || {};

  const result = await MeetingService.createInstantMeeting(
    userId,
    topic,
    undefined,
    true,
    undefined,
    latitude !== undefined ? Number(latitude) : undefined,
    longitude !== undefined ? Number(longitude) : undefined,
    locationAddress,
    preferredAttorney,
    preferredBailBondsman
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

const getMeetingSdkToken = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.getMeetingSdkToken(id, userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting SDK token retrieved successfully',
    data: result,
  });
});

const updateMeeting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.updateMeeting(userId, id, req.body);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting updated successfully',
    data: result,
  });
});

const deleteMeeting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.deleteMeeting(userId, id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Meeting deleted successfully',
    data: result,
  });
});

const leaveMeeting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.leaveMeeting(id, userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: result.message,
    data: result,
  });
});

const rejoinMeeting = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  MeetingService.hostRejoinedMeeting(id, userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Host rejoined meeting',
    data: { meetingId: id },
  });
});

const startRecording = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.startRecording(id, userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Recording started successfully',
    data: result,
  });
});

const stopRecording = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const result = await MeetingService.stopRecording(id, userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: result.message,
    data: result,
  });
});

const handleLiveKitWebhook = catchAsync(async (req: Request, res: Response) => {
  const rawBody =
    (req as any).rawBody ||
    (typeof req.body === 'string' ? req.body : JSON.stringify(req.body));
  const authHeader = req.headers.authorization;

  const result = await MeetingService.handleLiveKitWebhook(
    rawBody,
    authHeader
  );

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Webhook processed',
    data: result,
  });
});

const uploadRecordingDirect = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;

  let filePath = '';
  let fileSize = 0;

  // Extract uploaded file from multer
  if (req.files && typeof req.files === 'object') {
    const files = req.files as { [fieldname: string]: Express.Multer.File[] };
    const mediaFiles =
      files['media'] || files['file'] || files['attachment'] || files['doc'];
    if (mediaFiles && mediaFiles.length > 0) {
      const file = mediaFiles[0];
      const relPath = file.path.replace(/\\/g, '/');
      const baseIndex = relPath.indexOf('uploads/');
      filePath =
        baseIndex !== -1 ? '/' + relPath.substring(baseIndex) : `/${file.filename}`;
      fileSize = file.size;
    }
  } else if ((req as any).file) {
    const file = (req as any).file as Express.Multer.File;
    const relPath = file.path.replace(/\\/g, '/');
    const baseIndex = relPath.indexOf('uploads/');
    filePath =
      baseIndex !== -1 ? '/' + relPath.substring(baseIndex) : `/${file.filename}`;
    fileSize = file.size;
  }

  if (!filePath && req.body.recordingUrl) {
    filePath = req.body.recordingUrl;
  }

  if (!filePath) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      'No recording file or recordingUrl provided'
    );
  }

  // Construct absolute accessible URL if relative
  let fullUrl = filePath;
  if (filePath.startsWith('/')) {
    const protocol = req.protocol;
    const host = req.get('host');
    fullUrl = `${protocol}://${host}${filePath}`;
  }

  const result = await MeetingService.uploadRecordingDirect(
    id,
    fullUrl,
    fileSize,
    userId
  );

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Recording uploaded and attached successfully',
    data: result,
  });
});

const attachRecording = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const { recordingUrl } = req.body;

  const result = await MeetingService.attachRecording(
    id,
    recordingUrl,
    userId
  );

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Recording attached successfully',
    data: result,
  });
});

const getAllMeetingsForAdmin = catchAsync(async (req: Request, res: Response) => {
  const result = await MeetingService.getAllMeetingsForAdmin(req.query as any);
  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'All meetings retrieved successfully',
    data: result,
  });
});

export const MeetingController = {
  startGovia,
  emergencyCall,
  scheduleMeeting,
  updateMeeting,
  deleteMeeting,
  getMyMeetings,
  endMeeting,
  leaveMeeting,
  rejoinMeeting,
  syncRecording,
  cancelMeeting,
  getRecordings,
  getActiveMeetings,
  getAllMeetingsForAdmin,
  joinMeeting,
  getAttorneyRecordings,
  getMeetingSdkToken,
  startRecording,
  stopRecording,
  handleLiveKitWebhook,
  uploadRecordingDirect,
  attachRecording,
};


