import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { GiftPlanController } from './giftPlan.controller';
import { GiftPlanValidation } from './giftPlan.validation';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

// Retrieve available consumable gift packages
router.get('/packages', GiftPlanController.getGiftPackages);

// Purchase gift package & generate single-use codes (all roles)
router.post(
  '/purchase',
  auth(...allRoles),
  validateRequest(GiftPlanValidation.purchaseGiftPackageZodSchema),
  GiftPlanController.purchaseGiftPackage
);

// Get codes purchased by current user (with recipient tracking: who used the code, when)
router.get(
  '/my-purchases',
  auth(...allRoles),
  GiftPlanController.getMyPurchasedGifts
);

// Validate gift code and preview subscription details
router.post(
  '/validate',
  auth(...allRoles),
  validateRequest(GiftPlanValidation.validateGiftCodeZodSchema),
  GiftPlanController.validateGiftCode
);

// Atomically redeem gift code and activate subscription
router.post(
  '/redeem',
  auth(...allRoles),
  validateRequest(GiftPlanValidation.redeemGiftCodeZodSchema),
  GiftPlanController.redeemGiftCode
);

export const GiftPlanRoutes = router;
