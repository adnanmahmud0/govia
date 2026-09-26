import { z } from 'zod';

const updatePricingProfileZodSchema = z.object({
  body: z.object({
    serviceFee: z.number().min(0, 'Service fee must be non-negative').optional(),
    monthlyServiceFee: z.number().min(0, 'Monthly service fee must be non-negative').optional(),
    shortDescription: z.string().max(1000, 'Bio cannot exceed 1000 characters').optional(),
  }),
});

const createCheckoutSessionZodSchema = z.object({
  body: z.object({
    providerId: z.string({ required_error: 'Provider ID is required' }),
    successUrl: z.string().optional(),
    cancelUrl: z.string().optional(),
  }),
});

const updateCommissionZodSchema = z.object({
  body: z.object({
    platformCommissionPercent: z
      .number({ required_error: 'Commission percentage is required' })
      .min(0, 'Commission cannot be negative')
      .max(100, 'Commission cannot exceed 100%'),
  }),
});

export const ProviderPaymentValidation = {
  updatePricingProfileZodSchema,
  createCheckoutSessionZodSchema,
  updateCommissionZodSchema,
};
