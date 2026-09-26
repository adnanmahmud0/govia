import express from 'express';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { USER_ROLES } from '../../../enums/user';
import { ProviderPaymentController } from './providerPayment.controller';
import { ProviderPaymentValidation } from './providerPayment.validation';

const router = express.Router();

// 1. Provider Profile Pricing (Attorney & Bail Bondsman)
router.patch(
  '/pricing-profile',
  auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN, USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
  validateRequest(ProviderPaymentValidation.updatePricingProfileZodSchema),
  ProviderPaymentController.updatePricingProfile
);

// 2. Stripe Connect Express Payout Onboarding & Status
router.post(
  '/payout/onboard',
  auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN),
  ProviderPaymentController.createPayoutOnboard
);

router.get(
  '/payout/status',
  auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN),
  ProviderPaymentController.getPayoutStatus
);

router.get(
  '/payout/dashboard-link',
  auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN),
  ProviderPaymentController.getPayoutDashboardLink
);

// 3. Public Marketplace Directory for Citizens
router.get(
  '/directory',
  ProviderPaymentController.getProviderDirectory
);

// 4. Citizen Retainer Payment via Stripe Checkout
router.post(
  '/checkout-session',
  auth(USER_ROLES.CITIZEN),
  validateRequest(ProviderPaymentValidation.createCheckoutSessionZodSchema),
  ProviderPaymentController.createCheckoutSession
);

router.get(
  '/verify-session/:sessionId',
  ProviderPaymentController.verifySession
);

// 5. Stripe Webhook (Public, verified via signature/secret)
router.post(
  '/webhook',
  ProviderPaymentController.handleWebhook
);

// 6. Admin Commission Management
router.get(
  '/admin/commission',
  auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
  ProviderPaymentController.getCommission
);

router.put(
  '/admin/commission',
  auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
  validateRequest(ProviderPaymentValidation.updateCommissionZodSchema),
  ProviderPaymentController.updateCommission
);

// 7. Transactions
router.get(
  '/transactions',
  auth(
    USER_ROLES.SUPER_ADMIN,
    USER_ROLES.ADMIN,
    USER_ROLES.ATTORNEY,
    USER_ROLES.BAIL_BONDSMAN,
    USER_ROLES.CITIZEN
  ),
  ProviderPaymentController.getTransactions
);

export const ProviderPaymentRoutes = router;
