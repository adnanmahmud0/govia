import { z } from 'zod';
import {
  bearerAuth,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';

// GET /conversation
registry.registerPath({
  method: 'get',
  path: '/conversation',
  summary: 'Get User Conversations',
  description: 'Retrieves all conversations for the authenticated user with unread counts and last messages.',
  tags: ['Conversation'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [
    { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
    { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
  ],
  responses: {
    200: {
      description: 'Conversations retrieved successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(z.any())),
        },
      },
    },
  },
});

// GET /conversation/{id}
registry.registerPath({
  method: 'get',
  path: '/conversation/{id}',
  summary: 'Get Single Conversation Details',
  description: 'Retrieves conversation metadata and participant details.',
  tags: ['Conversation'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
  responses: {
    200: {
      description: 'Conversation retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any()),
        },
      },
    },
  },
});
