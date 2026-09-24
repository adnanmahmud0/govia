import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { SubscriptionController } from './subscription.controller';
import { SubscriptionValidation } from './subscription.validation';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

// Retrieve available subscription plans
router.get('/plans', SubscriptionController.getAvailablePlans);

// Get current user's subscription and monthly quota usage
router.get(
  '/my-status',
  auth(...allRoles),
  SubscriptionController.getMySubscriptionStatus
);

// Verify Google Play or Apple App Store In-App Purchase
router.post(
  '/verify-iap',
  auth(...allRoles),
  validateRequest(SubscriptionValidation.verifyIAPZodSchema),
  SubscriptionController.verifyIAP
);

// Direct subscription / manual upgrade
router.post(
  '/subscribe',
  auth(...allRoles),
  validateRequest(SubscriptionValidation.subscribeManualZodSchema),
  SubscriptionController.subscribeManual
);

// Cancel auto-renewal
router.post(
  '/cancel',
  auth(...allRoles),
  SubscriptionController.cancelSubscription
);

export const SubscriptionRoutes = router;
