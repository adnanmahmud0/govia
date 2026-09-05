import { z } from 'zod';
import { Types } from 'mongoose';

const sendMessageZodSchema = z.object({
  body: z.object({
    conversationId: z
      .string({
        required_error: 'conversationId is required',
      })
      .refine(val => Types.ObjectId.isValid(val), {
        message: 'Invalid conversationId ObjectId format',
      }),
    text: z.string().optional(),
    messageType: z.enum(['text', 'image', 'file', 'meeting']).optional(),
    meetingId: z
      .string()
      .optional()
      .refine(val => !val || Types.ObjectId.isValid(val), {
        message: 'Invalid meetingId ObjectId format',
      }),
  }),
});

const openChatZodSchema = z.object({
  body: z.object({
    participantId: z
      .string({
        required_error: 'participantId is required',
      })
      .refine(val => Types.ObjectId.isValid(val), {
        message: 'Invalid participantId ObjectId format',
      }),
  }),
});

const createMeetingMessageZodSchema = z.object({
  body: z.object({
    conversationId: z
      .string({
        required_error: 'conversationId is required',
      })
      .refine(val => Types.ObjectId.isValid(val), {
        message: 'Invalid conversationId ObjectId format',
      }),
    topic: z.string({
      required_error: 'Topic is required',
    }),
    meetingType: z.enum(['INSTANT', 'SCHEDULED'], {
      required_error: 'meetingType is required (INSTANT or SCHEDULED)',
    }),
    startTime: z.string().optional(),
    durationMinutes: z.number().min(5).max(1440).optional(),
    timezone: z.string().optional(),
    agenda: z.string().optional(),
  }),
});

export const MessageValidation = {
  sendMessageZodSchema,
  openChatZodSchema,
  createMeetingMessageZodSchema,
};


