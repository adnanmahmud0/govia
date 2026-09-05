import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { MeetingController } from './meeting.controller';
import { MeetingValidation } from './meeting.validation';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

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

// End a meeting and automatically attach Zoom cloud recordings
router.patch('/:id/end', auth(...allRoles), MeetingController.endMeeting);

// Sync / refresh meeting recordings from Zoom cloud
router.patch(
  '/:id/sync-recording',
  auth(...allRoles),
  MeetingController.syncRecording
);

// Cancel a scheduled meeting
router.patch('/:id/cancel', auth(...allRoles), MeetingController.cancelMeeting);

// Get list of active meetings (Attorney & Admin view)
router.get(
  '/active',
  auth(USER_ROLES.ATTORNEY, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  MeetingController.getActiveMeetings
);

// Join a meeting (Attorney action)
router.post(
  '/:meetingId/join',
  auth(USER_ROLES.ATTORNEY),
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

export const MeetingRoutes = router;
