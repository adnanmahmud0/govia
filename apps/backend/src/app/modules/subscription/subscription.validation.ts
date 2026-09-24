import { z } from 'zod';

const verifyIAPZodSchema = z.object({
  body: z.object({
    provider: z.enum(['APPLE_IAP', 'GOOGLE_PLAY', 'STRIPE', 'MANUAL'], {
      required_error: 'Payment provider is required',
    }),
    productId: z.string({
      required_error: 'Product ID is required',
    }),
    token: z.string({
      required_error: 'Purchase token or receipt data is required',
    }),
  }),
});

const subscribeManualZodSchema = z.object({
  body: z.object({
    plan: z.enum(['FREE', 'PREMIUM_MONTHLY', 'PREMIUM_YEARLY'], {
      required_error: 'Subscription plan is required',
    }),
    paymentProvider: z
      .enum(['APPLE_IAP', 'GOOGLE_PLAY', 'STRIPE', 'MANUAL'])
      .optional(),
  }),
});

export const SubscriptionValidation = {
  verifyIAPZodSchema,
  subscribeManualZodSchema,
};
