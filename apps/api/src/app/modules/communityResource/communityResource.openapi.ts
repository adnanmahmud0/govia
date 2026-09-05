import { z } from 'zod';
import {
  bearerAuth,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';

export const CommunityResourceSchema = z
  .object({
    _id: z.string().openapi({ example: '65ab1234567890abcdef1234' }),
    name: z.string().openapi({ example: 'Legal Aid Society' }),
    category: z.string().openapi({ example: 'Legal Support' }),
    phone: z.string().optional().openapi({ example: '+1-800-555-0199' }),
    email: z.string().optional().openapi({ example: 'info@legalaid.org' }),
    address: z.string().optional().openapi({ example: '123 Justice Way, NY' }),
    website: z.string().optional().openapi({ example: 'https://legalaid.org' }),
    description: z.string().optional(),
    image: z.string().optional(),
  })
  .openapi('CommunityResource');

// GET /communityResource
registry.registerPath({
  method: 'get',
  path: '/communityResource',
  summary: 'Get All Community Resources',
  description: 'Lists community resources with optional category filtering and search.',
  tags: ['CommunityResource'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [
    { name: 'category', in: 'query', schema: { type: 'string' } },
    { name: 'searchTerm', in: 'query', schema: { type: 'string' } },
  ],
  responses: {
    200: {
      description: 'Resources retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(CommunityResourceSchema)),
        },
      },
    },
  },
});

// GET /communityResource/{id}
registry.registerPath({
  method: 'get',
  path: '/communityResource/{id}',
  summary: 'Get Single Community Resource',
  description: 'Retrieves complete details of a specific community resource.',
  tags: ['CommunityResource'],
  security: [{ [bearerAuth.name]: [] }],
  parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
  responses: {
    200: {
      description: 'Resource details retrieved',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(CommunityResourceSchema),
        },
      },
    },
  },
});
