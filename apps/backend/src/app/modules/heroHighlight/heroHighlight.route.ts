import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { HeroHighlightController } from './heroHighlight.controller';
import { HeroHighlightValidation } from './heroHighlight.validation';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

// 1. Officers discovery & lookup
router.get('/officers', auth(...allRoles), HeroHighlightController.getOfficers);
router.get('/officers/lookup/:identifier', auth(...allRoles), HeroHighlightController.lookupOfficer);

// 2. Highlights feed & creation
router.post(
  '/',
  auth(USER_ROLES.CITIZEN, USER_ROLES.USER, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  validateRequest(HeroHighlightValidation.createHeroHighlightZodSchema),
  HeroHighlightController.createHeroHighlight
);

router.get('/', auth(...allRoles), HeroHighlightController.getHeroHighlights);

// 3. Salutes & single item
router.patch('/:id/salute', auth(...allRoles), HeroHighlightController.toggleSalute);
router.get('/:id', auth(...allRoles), HeroHighlightController.getSingleHeroHighlight);

export const HeroHighlightRoutes = router;
