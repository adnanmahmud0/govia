import { z } from 'zod';
import { Types } from 'mongoose';

const createConversationZodSchema = z.object({
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

export const ConversationValidation = {
  createConversationZodSchema,
};

