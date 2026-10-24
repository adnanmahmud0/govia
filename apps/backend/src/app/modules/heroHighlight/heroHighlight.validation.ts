import { z } from 'zod';

const createHeroHighlightZodSchema = z.object({
  body: z.object({
    officerId: z.string().optional(),
    officerName: z.string({
      required_error: 'Officer Name is required',
    }),
    officerRank: z.string().optional(),
    badgeNumber: z.string().optional(),
    agency: z.string({
      required_error: 'Agency is required',
    }),
    carNumber: z.string().optional().default(''),
    officerAvatar: z.string().optional(),
    overallRating: z
      .number()
      .min(1, 'Rating must be at least 1')
      .max(5, 'Rating must be at most 5')
      .optional(),
    respectRating: z
      .number()
      .min(0, 'Rating must be at least 0')
      .max(10, 'Rating must be at most 10')
      .optional(),
    deEscalationRating: z
      .number()
      .min(0, 'Rating must be at least 0')
      .max(10, 'Rating must be at most 10')
      .optional(),
    communicationRating: z
      .number()
      .min(0, 'Rating must be at least 0')
      .max(10, 'Rating must be at most 10')
      .optional(),
    whatDidOfficerDoWell: z.string({
      required_error: 'Feedback is required',
    }),
    incidentDate: z.string().optional(),
    incidentLocation: z.string().optional(),
    shareWithAgency: z.boolean().optional(),
    includeInMetrics: z.boolean().optional(),
    shareWithCourt: z.boolean().optional(),
  }),
});

export const HeroHighlightValidation = {
  createHeroHighlightZodSchema,
};
