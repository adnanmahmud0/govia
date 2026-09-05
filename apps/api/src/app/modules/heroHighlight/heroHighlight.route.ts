import express from 'express';
import { HeroHighlightController } from './heroHighlight.controller';
import validateRequest from '../../middlewares/validateRequest';
import { HeroHighlightValidation } from './heroHighlight.validation';
import auth from '../../middlewares/auth';
import { USER_ROLES } from '../../../enums/user';

const router = express.Router();

router.post(
  '/',
  auth(USER_ROLES.USER, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN), // Add roles as appropriate for your app
  validateRequest(HeroHighlightValidation.createHeroHighlightZodSchema),
  HeroHighlightController.createHeroHighlight
);

router.get(
  '/',
  auth(USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN), // Usually getting all feedback is restricted, adjust if needed
  HeroHighlightController.getHeroHighlights
);

router.get(
  '/:id',
  auth(USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  HeroHighlightController.getSingleHeroHighlight
);

export const HeroHighlightRoutes = router;
