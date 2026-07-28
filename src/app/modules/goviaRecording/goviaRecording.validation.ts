import { z } from 'zod';

const createRecordingZodSchema = z.object({
  body: z.object({
    title: z.string({
      required_error: 'Title is required',
    }),
    description: z.string({
      required_error: 'Description is required',
    }),
    location: z.string({
      required_error: 'Location is required',
    }),
    date: z.string().optional(), // Will use current date if not provided
    recordingUrl: z.string().optional(),
  }),
});

export const GoviaRecordingValidation = {
  createRecordingZodSchema,
};
