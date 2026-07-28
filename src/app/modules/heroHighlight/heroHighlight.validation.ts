import { z } from 'zod';

const createHeroHighlightZodSchema = z.object({
  body: z.object({
    officerName: z.string({
      required_error: 'Officer Name is required',
    }),
    badgeNumber: z.string().optional(),
    agency: z.string({
      required_error: 'Agency is required',
    }),
    carNumber: z.string({
      required_error: 'Car Number is required',
    }),
    respectRating: z
      .number({
        required_error: 'Respect Rating is required',
      })
      .min(0, 'Rating must be at least 0')
      .max(10, 'Rating must be at most 10'),
    deEscalationRating: z
      .number({
        required_error: 'De-escalation Rating is required',
      })
      .min(0, 'Rating must be at least 0')
      .max(10, 'Rating must be at most 10'),
    communicationRating: z
      .number({
        required_error: 'Communication Rating is required',
      })
      .min(0, 'Rating must be at least 0')
      .max(10, 'Rating must be at most 10'),
    whatDidOfficerDoWell: z.string({
      required_error: 'Feedback is required',
    }),
    incidentDate: z.string({
      required_error: 'Incident Date is required',
    }),
    incidentLocation: z.string({
      required_error: 'Incident Location is required',
    }),
    shareWithAgency: z.boolean().optional(),
    includeInMetrics: z.boolean().optional(),
    shareWithCourt: z.boolean().optional(),
  }),
});

export const HeroHighlightValidation = {
  createHeroHighlightZodSchema,
};
