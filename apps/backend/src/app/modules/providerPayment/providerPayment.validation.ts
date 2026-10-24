import { z } from 'zod';

const updatePricingProfileZodSchema = z.object({
  body: z.object({
    shortDescription: z.string().max(1000, 'Bio cannot exceed 1000 characters').optional(),
  }),
});

const createCheckoutSessionZodSchema = z.object({
  body: z.object({
    providerId: z.string().optional(),
    role: z.enum(['ATTORNEY', 'BAIL_BONDSMAN']).optional(),
    successUrl: z.string().optional(),
    cancelUrl: z.string().optional(),
  }),
});

const createServiceCheckoutSessionZodSchema = z.object({
  body: z.object({
    role: z.enum(['ATTORNEY', 'BAIL_BONDSMAN']),
    successUrl: z.string().optional(),
    cancelUrl: z.string().optional(),
  }),
});

const selectPreferredProviderZodSchema = z.object({
  body: z.object({
    providerId: z.string({ required_error: 'Provider ID is required' }),
    role: z.enum(['ATTORNEY', 'BAIL_BONDSMAN']),
  }),
});

const updateCommissionZodSchema = z.object({
  body: z.object({
    platformCommissionPercent: z
      .number()
      .min(0, 'Commission cannot be negative')
      .max(100, 'Commission cannot exceed 100%')
      .optional(),
    attorneyServiceFee: z.number().min(0, 'Attorney fee must be non-negative').optional(),
    bailBondsmanServiceFee: z.number().min(0, 'Bail bondsman fee must be non-negative').optional(),
  }),
});

const updateServiceChargeZodSchema = z.object({
  body: z.object({
    attorneyServiceFee: z.number().min(0, 'Attorney fee must be non-negative').optional(),
    bailBondsmanServiceFee: z.number().min(0, 'Bail bondsman fee must be non-negative').optional(),
    platformCommissionPercent: z.number().min(0).max(100).optional(),
  }),
});

export const ProviderPaymentValidation = {
  updatePricingProfileZodSchema,
  createCheckoutSessionZodSchema,
  createServiceCheckoutSessionZodSchema,
  selectPreferredProviderZodSchema,
  updateCommissionZodSchema,
  updateServiceChargeZodSchema,
};
