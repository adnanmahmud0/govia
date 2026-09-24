import { z } from 'zod';

const generateResponseZodSchema = z.object({
  body: z.object({
    chatId: z.string().optional(),
    prompt: z.string({
      required_error: 'Prompt is required',
    }),
    history: z
      .array(
        z.object({
          role: z.enum(['system', 'user', 'assistant']),
          content: z.string(),
        })
      )
      .optional(),
  }),
});

export const AiAssistantValidation = {
  generateResponseZodSchema,
};
