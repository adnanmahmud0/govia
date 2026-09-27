import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { ReferralController } from './referral.controller';
import { ReferralValidation } from './referral.validation';

const router = express.Router();

const citizenRoles = [USER_ROLES.CITIZEN, USER_ROLES.USER];
const adminRoles = [USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN];

// Citizen-Exclusive: Get referral summary (code, link, points balance, tier)
router.get(
  '/summary',
  auth(...citizenRoles),
  ReferralController.getReferralSummary
);

// Citizen-Exclusive: Get referral history
router.get(
  '/history',
  auth(...citizenRoles),
  ReferralController.getReferralHistory
);

// Citizen-Exclusive: Get rewards catalog
router.get(
  '/rewards-catalog',
  auth(...citizenRoles),
  ReferralController.getRewardsCatalog
);

// Citizen-Exclusive: Redeem a reward with points
router.post(
  '/redeem',
  auth(...citizenRoles),
  validateRequest(ReferralValidation.redeemRewardZodSchema),
  ReferralController.redeemReward
);

// Citizen-Exclusive: Point transaction history
router.get(
  '/transactions',
  auth(...citizenRoles),
  ReferralController.getPointTransactions
);

// Admin-Only: Referral system platform overview
router.get(
  '/admin/overview',
  auth(...adminRoles),
  ReferralController.getAdminReferralOverview
);

export const ReferralRoutes = router;
