import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import fileUploadHandler from '../../middlewares/fileUploadHandler';
import validateRequest from '../../middlewares/validateRequest';
import { MeetingController } from './meeting.controller';
import { MeetingValidation } from './meeting.validation';
import { RiskAnalyticsController } from './riskAnalytics.controller';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

// LiveKit Cloud recording webhook (egress_ended, room_finished)
router.post('/webhook/livekit', MeetingController.handleLiveKitWebhook);

// Instant consultation meeting (open to all roles)
router.post(
  '/start-govia',
  auth(...allRoles),
  validateRequest(MeetingValidation.startInstantMeetingZodSchema),
  MeetingController.startGovia
);

// Emergency call (Citizens and regular users)
router.post(
  '/emergency-call',
  auth(USER_ROLES.USER, USER_ROLES.CITIZEN),
  MeetingController.emergencyCall
);

// Schedule a future meeting (open to all roles)
router.post(
  '/schedule',
  auth(...allRoles),
  validateRequest(MeetingValidation.scheduleMeetingZodSchema),
  MeetingController.scheduleMeeting
);

// Get current user's meetings / schedule page (upcoming, scheduled, active, past) - open to all roles
router.get('/my-meetings', auth(...allRoles), MeetingController.getMyMeetings);
router.get('/schedule', auth(...allRoles), MeetingController.getMyMeetings);

// Update a scheduled meeting
router.patch('/:id', auth(...allRoles), MeetingController.updateMeeting);

// Delete a meeting
router.delete('/:id', auth(...allRoles), MeetingController.deleteMeeting);

// End a meeting and automatically attach cloud recordings
router.patch('/:id/end', auth(...allRoles), MeetingController.endMeeting);
router.post('/:id/end', auth(...allRoles), MeetingController.endMeeting);

// Leave a meeting (participants exit cleanly, host triggers 5-min auto-end)
router.post('/:id/leave', auth(...allRoles), MeetingController.leaveMeeting);
router.patch('/:id/leave', auth(...allRoles), MeetingController.leaveMeeting);

// Host rejoined meeting (clears 5-min grace timer)
router.post('/:id/rejoin', auth(...allRoles), MeetingController.rejoinMeeting);

// Sync / refresh meeting recordings from Zoom cloud
router.patch(
  '/:id/sync-recording',
  auth(...allRoles),
  MeetingController.syncRecording
);

// Start cloud/incident recording
router.post(
  '/:id/recording/start',
  auth(...allRoles),
  MeetingController.startRecording
);

// Stop cloud/incident recording
router.post(
  '/:id/recording/stop',
  auth(...allRoles),
  MeetingController.stopRecording
);

// Direct recording video file upload (multipart/form-data)
router.post(
  '/:id/recording-upload',
  auth(...allRoles),
  fileUploadHandler(),
  MeetingController.uploadRecordingDirect
);

// Attach recording URL directly
router.post(
  '/:id/attach-recording',
  auth(...allRoles),
  MeetingController.attachRecording
);

// Cancel a scheduled meeting
router.patch('/:id/cancel', auth(...allRoles), MeetingController.cancelMeeting);

// Get ALL meetings for admin (call history)
router.get(
  '/admin-all',
  auth(USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  MeetingController.getAllMeetingsForAdmin
);

// Get Risk Map & Tactical Analytics telemetry
router.get(
  '/risk-analytics',
  auth(USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  RiskAnalyticsController.getRiskAnalytics
);

// Get list of active meetings (Attorney & Admin view)
router.get(
  '/active',
  auth(USER_ROLES.ATTORNEY, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  MeetingController.getActiveMeetings
);

// Join a meeting (open to all roles)
router.post(
  '/:meetingId/join',
  auth(...allRoles),
  MeetingController.joinMeeting
);

// Get recordings for meetings the attorney has joined
router.get(
  '/attorney-recordings',
  auth(USER_ROLES.ATTORNEY),
  MeetingController.getAttorneyRecordings
);

// Get recordings for a specific meeting
router.get(
  '/:meetingId/recordings',
  auth(...allRoles),
  MeetingController.getRecordings
);

// Get fresh LiveKit / SDK token for a meeting
router.get(
  '/:id/sdk-token',
  auth(...allRoles),
  MeetingController.getMeetingSdkToken
);
router.get(
  '/:id/token',
  auth(...allRoles),
  MeetingController.getMeetingSdkToken
);

export const MeetingRoutes = router;
