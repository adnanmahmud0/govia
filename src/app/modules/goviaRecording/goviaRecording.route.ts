import express from 'express';
import { GoviaRecordingController } from './goviaRecording.controller';
import validateRequest from '../../middlewares/validateRequest';
import { GoviaRecordingValidation } from './goviaRecording.validation';
import auth from '../../middlewares/auth';
import { USER_ROLES } from '../../../enums/user';

const router = express.Router();

router.post(
  '/',
  auth(USER_ROLES.USER, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  validateRequest(GoviaRecordingValidation.createRecordingZodSchema),
  GoviaRecordingController.createRecording
);

router.get(
  '/',
  auth(USER_ROLES.USER, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  GoviaRecordingController.getRecordings
);

export const GoviaRecordingRoutes = router;
