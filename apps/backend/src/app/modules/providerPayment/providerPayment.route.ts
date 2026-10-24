import express from 'express';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { USER_ROLES } from '../../../enums/user';
import { ProviderPaymentController } from './providerPayment.controller';
import { ProviderPaymentValidation } from './providerPayment.validation';

const router = express.Router();

// 1. Provider Profile Bio (Service Pricing removed from providers)
router.route('/pricing-profile')
  .patch(
    auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN, USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
    validateRequest(ProviderPaymentValidation.updatePricingProfileZodSchema),
    ProviderPaymentController.updatePricingProfile
  )
  .put(
    auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN, USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
    validateRequest(ProviderPaymentValidation.updatePricingProfileZodSchema),
    ProviderPaymentController.updatePricingProfile
  );

// 2. Platform Service Charges (Admin configured, Publicly readable)
router.get(
  '/service-charge',
  ProviderPaymentController.getServiceCharge
);

router.put(
  '/admin/service-charge',
  auth(USER_ROLES.SUPER_ADMIN, USER_ROLES.ADMIN),
  validateRequest(ProviderPaymentValidation.updateServiceChargeZodSchema),
  ProviderPaymentController.updateServiceCharge
);

// 3. Public Marketplace Directory for Citizens
router.get(
  '/directory',
  ProviderPaymentController.getProviderDirectory
);

// 4. Citizen Service Checkout via Stripe
router.post(
  '/service-checkout',
  auth(USER_ROLES.CITIZEN, USER_ROLES.USER),
  validateRequest(ProviderPaymentValidation.createServiceCheckoutSessionZodSchema),
  ProviderPaymentController.createServiceCheckoutSession
);

// Backward-compatible checkout session
router.post(
  '/checkout-session',
  auth(USER_ROLES.CITIZEN, USER_ROLES.USER),
  validateRequest(ProviderPaymentValidation.createCheckoutSessionZodSchema),
  ProviderPaymentController.createCheckoutSession
);

router.get(
  '/verify-session/:sessionId',
  ProviderPaymentController.verifySession
);

// 5. Gated Preferred Provider Selection (requires active paid service coverage)
router.post(
  '/select-preferred',
  auth(USER_ROLES.CITIZEN, USER_ROLES.USER),
  validateRequest(ProviderPaymentValidation.selectPreferredProviderZodSchema),
  ProviderPaymentController.selectPreferredProvider
);

// 6. Stripe Webhook (Public, verified via signature/secret)
router.post(
  '/webhook',
  ProviderPaymentController.handleWebhook
);

// 7. Admin Commission / Settings (Backward-compatible)
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

// 8. Transactions
router.get(
  '/transactions',
  auth(
    USER_ROLES.SUPER_ADMIN,
    USER_ROLES.ADMIN,
    USER_ROLES.ATTORNEY,
    USER_ROLES.BAIL_BONDSMAN,
    USER_ROLES.CITIZEN,
    USER_ROLES.USER
  ),
  ProviderPaymentController.getTransactions
);

// 9. Payout routes (Deprecated stubs)
router.post(
  ['/payout/onboard', '/payout-account', '/payout/account'],
  auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN),
  ProviderPaymentController.createPayoutOnboard
);

router.get(
  ['/payout/status', '/payout-status'],
  auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN),
  ProviderPaymentController.getPayoutStatus
);

router.get(
  ['/payout/dashboard-link', '/payout-dashboard'],
  auth(USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN),
  ProviderPaymentController.getPayoutDashboardLink
);

export const ProviderPaymentRoutes = router;
