import { z } from 'zod';

const createCommunityResourceZodSchema = z.object({
  body: z.object({
    name: z.string({
      required_error: 'Name is required',
    }),
    shortName: z.string().optional(),
    email: z.string().email().optional(),
    phone: z.string().optional(),
    websiteUrl: z.string().url().optional(),
  }),
});

const updateCommunityResourceZodSchema = z.object({
  body: z.object({
    name: z.string().optional(),
    shortName: z.string().optional(),
    email: z.string().email().optional(),
    phone: z.string().optional(),
    websiteUrl: z.string().url().optional(),
  }),
});

export const CommunityResourceValidation = {
  createCommunityResourceZodSchema,
  updateCommunityResourceZodSchema,
};
