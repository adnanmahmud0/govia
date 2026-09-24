import { z } from 'zod';
import {
  bearerAuth,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';
import { MessageValidation } from './message.validation';

export const SendMessageRequestSchema = MessageValidation.sendMessageZodSchema.shape.body.openapi({
  description: 'Send chat message payload',
  example: {
    conversationId: '651234567890abcdef123456',
    text: 'Hello, I have a question about my consultation.',
    messageType: 'text',
  },
});

export const CreateMeetingInChatRequestSchema = MessageValidation.createMeetingMessageZodSchema.shape.body.openapi({
  description: 'Create instant or scheduled meeting from inside chat thread',
  example: {
    conversationId: '651234567890abcdef123456',
    topic: 'Case Discussion',
    meetingType: 'SCHEDULED',
    startTime: '2026-09-15T15:00:00.000Z',
    durationMinutes: 30,
  },
});

export const OpenChatRequestSchema = MessageValidation.openChatZodSchema.shape.body.openapi({
  description: 'Click-to-chat payload with target user ID',
  example: {
    participantId: '64bcde1234567890abcdef12',
  },
});

export const MessageResponseDataSchema = z
  .object({
    _id: z.string().openapi({ example: '65fe1234567890abcdef1234' }),
    conversationId: z.string().openapi({ example: '651234567890abcdef123456' }),
    sender: z.any(),
    receiver: z.any(),
    text: z.string().optional(),
    messageType: z.enum(['text', 'image', 'file', 'meeting']).openapi({ example: 'text' }),
    meetingId: z.any().optional(),
    attachment: z.string().optional(),
    read: z.boolean().openapi({ example: false }),
    createdAt: z.string(),
  })
  .openapi('MessageResponseData');

// POST /message
registry.registerPath({
  method: 'post',
  path: '/message',
  summary: 'Send Message',
  description: 'Sends a text message or file attachment to a conversation.',
  tags: ['Message'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: SendMessageRequestSchema,
        },
      },
    },
  },
  responses: {
    201: {
      description: 'Message sent successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(MessageResponseDataSchema),
        },
      },
    },
  },
});

// POST /message/meeting
registry.registerPath({
  method: 'post',
  path: '/message/meeting',
  summary: 'Create Meeting In Chat ("Now" or "Later")',
  description: 'Creates an instant or scheduled Zoom meeting directly within a conversation, generating a chat card and syncing to Schedule Page.',
  tags: ['Message'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: CreateMeetingInChatRequestSchema,
        },
      },
    },
  },
  responses: {
    201: {
      description: 'Meeting created and posted to chat',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any()),
        },
      },
    },
  },
});

// GET /message/search-users
registry.registerPath({
  method: 'get',
  path: '/message/search-users',
  summary: 'Search Users Across All Roles',
  description: 'Searches users by name, role, email with precomputed direct conversation IDs for 1-click messaging.',
  tags: ['Message'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [
    { name: 'searchTerm', in: 'query', schema: { type: 'string' } },
    { name: 'role', in: 'query', schema: { type: 'string' } },
    { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
    { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
  ],
  responses: {
    200: {
      description: 'Users retrieved for messaging',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(z.any())),
        },
      },
    },
  },
});

// POST /message/open-chat
registry.registerPath({
  method: 'post',
  path: '/message/open-chat',
  summary: 'Open or Create Chat Thread',
  description: 'Click-action on search result to retrieve existing conversation or create new thread atomically.',
  tags: ['Message'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: OpenChatRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Conversation retrieved or created',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any()),
        },
      },
    },
  },
});

// GET /message/{conversationId}
registry.registerPath({
  method: 'get',
  path: '/message/{conversationId}',
  summary: 'Get Messages by Conversation',
  description: 'Retrieves chronological chat history with populated meeting status and attachments.',
  tags: ['Message'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [
    { name: 'conversationId', in: 'path', required: true, schema: { type: 'string' } },
    { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
    { name: 'limit', in: 'query', schema: { type: 'integer', default: 50 } },
  ],
  responses: {
    200: {
      description: 'Messages retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(MessageResponseDataSchema)),
        },
      },
    },
  },
});

// PATCH /message/read/{conversationId}
registry.registerPath({
  method: 'patch',
  path: '/message/read/{conversationId}',
  summary: 'Mark Messages as Read',
  description: 'Marks unread messages in the thread as read and emits real-time read receipt.',
  tags: ['Message'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [{ name: 'conversationId', in: 'path', required: true, schema: { type: 'string' } }],
  responses: {
    200: {
      description: 'Messages marked as read',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any()),
        },
      },
    },
  },
});
