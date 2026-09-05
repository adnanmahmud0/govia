import { z } from 'zod';
import {
  bearerAuth,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';

// GET /goviaRecording
registry.registerPath({
  method: 'get',
  path: '/goviaRecording',
  summary: 'Get Govia Recordings',
  description: 'Retrieves user recordings and encounter evidence files.',
  tags: ['GoviaRecording'],
  security: [{ [bearerAuth.name]: [] }],
  responses: {
    200: {
      description: 'Recordings retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(z.any())),
        },
      },
    },
  },
});
