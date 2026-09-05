import { z } from 'zod';
import {
  bearerAuth,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';
import { MeetingValidation } from './meeting.validation';

export const ScheduleMeetingRequestSchema = MeetingValidation.scheduleMeetingZodSchema.shape.body.openapi({
  description: 'Schedule a Zoom meeting payload',
  example: {
    participantId: '64bcde1234567890abcdef12',
    conversationId: '651234567890abcdef123456',
    topic: 'Case Planning & Consultation',
    startTime: '2026-09-15T14:00:00.000Z',
    durationMinutes: 45,
    timezone: 'America/New_York',
    agenda: 'Case discovery and next steps',
  },
});

export const StartInstantMeetingRequestSchema = MeetingValidation.startInstantMeetingZodSchema.shape.body.openapi({
  description: 'Start instant Zoom consultation meeting payload',
  example: {
    topic: 'Immediate Govia Consultation',
    participantId: '64bcde1234567890abcdef12',
    conversationId: '651234567890abcdef123456',
  },
});

export const MeetingResponseDataSchema = z
  .object({
    _id: z.string().openapi({ example: '65ab1234567890abcdef1234' }),
    topic: z.string().openapi({ example: 'Case Planning & Consultation' }),
    meetingType: z.enum(['INSTANT', 'SCHEDULED', 'EMERGENCY']).openapi({ example: 'SCHEDULED' }),
    status: z.enum(['SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED']).openapi({ example: 'SCHEDULED' }),
    joinUrl: z.string().openapi({ example: 'https://zoom.us/j/123456789?pwd=...' }),
    startUrl: z.string().openapi({ example: 'https://zoom.us/s/123456789?...' }),
    recordingUrl: z.string().optional().openapi({ example: 'https://zoom.us/rec/share/...' }),
    recordings: z.array(z.any()).optional(),
    startTime: z.string().optional(),
    durationMinutes: z.number().optional(),
    endedAt: z.string().optional(),
    userId: z.any(),
    participantId: z.any().optional(),
  })
  .openapi('MeetingResponseData');

// POST /meeting/schedule
registry.registerPath({
  method: 'post',
  path: '/meeting/schedule',
  summary: 'Schedule a Future Meeting',
  description: 'Schedules a future Zoom meeting. Open to ALL roles. If conversationId is provided, it syncs with chat.',
  tags: ['Meeting'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: ScheduleMeetingRequestSchema,
        },
      },
    },
  },
  responses: {
    201: {
      description: 'Meeting scheduled successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(MeetingResponseDataSchema),
        },
      },
    },
  },
});

// GET /meeting/schedule
registry.registerPath({
  method: 'get',
  path: '/meeting/schedule',
  summary: 'Get Scheduled & Past Meetings (Schedule Page)',
  description: 'Returns meetings where the user is host, invitee, or joined attorney with timeFilter and status filters.',
  tags: ['Meeting'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [
    { name: 'timeFilter', in: 'query', schema: { type: 'string', enum: ['upcoming', 'past'] }, description: 'Filter upcoming or past meetings' },
    { name: 'status', in: 'query', schema: { type: 'string', enum: ['SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED'] } },
    { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
    { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
  ],
  responses: {
    200: {
      description: 'Meetings retrieved successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(MeetingResponseDataSchema)),
        },
      },
    },
  },
});

// POST /meeting/start-govia
registry.registerPath({
  method: 'post',
  path: '/meeting/start-govia',
  summary: 'Start Instant Consultation Meeting',
  description: 'Instantly creates an active Zoom consultation meeting. Open to all roles.',
  tags: ['Meeting'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: StartInstantMeetingRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Instant meeting created successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(MeetingResponseDataSchema),
        },
      },
    },
  },
});

// POST /meeting/emergency-call
registry.registerPath({
  method: 'post',
  path: '/meeting/emergency-call',
  summary: 'Emergency Protocol Call ("I Feel Unsafe")',
  description: 'Triggered by Citizens during an encounter to instantly start an emergency call and notify attorneys.',
  tags: ['Meeting'],
  security: [{ [bearerAuth.name]: [] }],
  responses: {
    200: {
      description: 'Emergency meeting created and broadcasted',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(MeetingResponseDataSchema),
        },
      },
    },
  },
});

// PATCH /meeting/{id}/end
registry.registerPath({
  method: 'patch',
  path: '/meeting/{id}/end',
  summary: 'End Meeting & Attach Recordings',
  description: 'Ends active meeting, sets status to COMPLETED, fetches Zoom cloud recordings, and replaces "Join Now" with recording playback.',
  tags: ['Meeting'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
  responses: {
    200: {
      description: 'Meeting ended and recordings attached',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(MeetingResponseDataSchema),
        },
      },
    },
  },
});

// PATCH /meeting/{id}/sync-recording
registry.registerPath({
  method: 'patch',
  path: '/meeting/{id}/sync-recording',
  summary: 'Refresh / Sync Cloud Recordings',
  description: 'Synchronizes Zoom cloud recordings to MongoDB if processing finished after call conclusion.',
  tags: ['Meeting'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
  responses: {
    200: {
      description: 'Recordings synchronized',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(MeetingResponseDataSchema),
        },
      },
    },
  },
});
