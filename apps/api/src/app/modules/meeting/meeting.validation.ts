import { z } from 'zod';
import { Types } from 'mongoose';

const scheduleMeetingZodSchema = z.object({
  body: z.object({
    participantId: z
      .string()
      .optional()
      .refine(val => !val || Types.ObjectId.isValid(val), {
        message: 'Invalid participantId ObjectId format',
      }),
    conversationId: z
      .string()
      .optional()
      .refine(val => !val || Types.ObjectId.isValid(val), {
        message: 'Invalid conversationId ObjectId format',
      }),
    topic: z.string({
      required_error: 'Topic is required',
    }),
    startTime: z.string({
      required_error: 'Start time is required (ISO 8601 string)',
    }),
    durationMinutes: z.number().min(5).max(1440).optional(),
    timezone: z.string().optional(),
    agenda: z.string().optional(),
  }),
});

const startInstantMeetingZodSchema = z.object({
  body: z.object({
    topic: z.string().optional(),
    participantId: z
      .string()
      .optional()
      .refine(val => !val || Types.ObjectId.isValid(val), {
        message: 'Invalid participantId ObjectId format',
      }),
    conversationId: z
      .string()
      .optional()
      .refine(val => !val || Types.ObjectId.isValid(val), {
        message: 'Invalid conversationId ObjectId format',
      }),
  }),
});

export const MeetingValidation = {
  scheduleMeetingZodSchema,
  startInstantMeetingZodSchema,
};

