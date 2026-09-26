import { z } from 'zod';

const purchaseGiftPackageZodSchema = z.object({
  body: z.object({
    productId: z.string({
      required_error: 'Product ID is required',
    }),
    provider: z.enum(['APPLE_IAP', 'GOOGLE_PLAY', 'STRIPE', 'MANUAL'], {
      required_error: 'Payment provider is required',
    }),
    purchaseToken: z.string().optional(),
    transactionId: z.string().optional(),
  }),
});

const validateGiftCodeZodSchema = z.object({
  body: z.object({
    code: z
      .string({
        required_error: 'Gift code is required',
      })
      .min(3, 'Gift code must be at least 3 characters'),
  }),
});

const redeemGiftCodeZodSchema = z.object({
  body: z.object({
    code: z
      .string({
        required_error: 'Gift code is required',
      })
      .min(3, 'Gift code must be at least 3 characters'),
  }),
});

export const GiftPlanValidation = {
  purchaseGiftPackageZodSchema,
  validateGiftCodeZodSchema,
  redeemGiftCodeZodSchema,
};
