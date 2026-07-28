import express from 'express';
import { MeetingController } from './meeting.controller';
import auth from '../../middlewares/auth';
import { USER_ROLES } from '../../../enums/user';

const router = express.Router();

router.post(
  '/start-govia',
  auth(USER_ROLES.USER, USER_ROLES.CITIZEN),
  MeetingController.startGovia
);

router.post(
  '/emergency-call',
  auth(USER_ROLES.USER, USER_ROLES.CITIZEN),
  MeetingController.emergencyCall
);

// Get recordings (admin or specific user check might be needed, currently just protecting it)
router.get(
  '/:meetingId/recordings',
  auth(USER_ROLES.USER, USER_ROLES.CITIZEN, USER_ROLES.ATTORNEY),
  MeetingController.getRecordings
);

// Get list of active meetings (Attorney view)
router.get(
  '/active',
  auth(USER_ROLES.ATTORNEY, USER_ROLES.ADMIN),
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

export const MeetingRoutes = router;
