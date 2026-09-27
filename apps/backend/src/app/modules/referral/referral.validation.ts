import { z } from 'zod';

const redeemRewardZodSchema = z.object({
  body: z.object({
    rewardId: z.string({
      required_error: 'Reward ID is required',
    }),
  }),
});

export const ReferralValidation = {
  redeemRewardZodSchema,
};
