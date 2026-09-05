import { z } from 'zod';
import {
  bearerAuth,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';

// POST /aiAssistant
registry.registerPath({
  method: 'post',
  path: '/aiAssistant',
  summary: 'Chat with AI Assistant',
  description: 'Sends a prompt to Govia AI Assistant for legal guidance, encounter rights, and crisis assistance.',
  tags: ['AiAssistant'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: z.object({
            message: z.string().openapi({ example: 'What are my rights during a traffic stop?' }),
            chatId: z.string().optional().openapi({ example: '65ab1234567890abcdef1234' }),
          }),
        },
      },
    },
  },
  responses: {
    200: {
      description: 'AI response generated',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any()),
        },
      },
    },
  },
});

// GET /aiAssistant/chats
registry.registerPath({
  method: 'get',
  path: '/aiAssistant/chats',
  summary: 'Get AI Chat List',
  description: 'Retrieves all previous conversation threads with the AI Assistant.',
  tags: ['AiAssistant'],
  security: [{ [bearerAuth.name]: [] }],
  responses: {
    200: {
      description: 'Chats retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(z.any())),
        },
      },
    },
  },
});

// GET /aiAssistant/chats/{id}
registry.registerPath({
  method: 'get',
  path: '/aiAssistant/chats/{id}',
  summary: 'Get Chat History',
  description: 'Retrieves full message history of a specific AI chat thread.',
  tags: ['AiAssistant'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
  responses: {
    200: {
      description: 'Chat history retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any()),
        },
      },
    },
  },
});
