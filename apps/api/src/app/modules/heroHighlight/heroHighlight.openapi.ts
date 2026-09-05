import { z } from 'zod';
import {
  bearerAuth,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';

// GET /heroHighlight
registry.registerPath({
  method: 'get',
  path: '/heroHighlight',
  summary: 'Get Hero Highlights',
  description: 'Retrieves all hero highlights and testimonials.',
  tags: ['HeroHighlight'],
  security: [{ [bearerAuth.name]: [] }],
  responses: {
    200: {
      description: 'Hero highlights retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(z.any())),
        },
      },
    },
  },
});
