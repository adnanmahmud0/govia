import { z } from 'zod';
import {
  bearerAuth,
  createErrorResponseSchema,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';
import { UserValidation } from './user.validation';

export const CreateUserRequestSchema = UserValidation.createUserZodSchema.shape.body.openapi({
  description: 'User registration payload',
  example: {
    name: 'John Citizen',
    email: 'john@example.com',
    role: 'CITIZEN',
    password: 'Password123!',
    phoneNumber: '+1234567890',
  },
});

export const UserResponseDataSchema = z
  .object({
    _id: z.string().openapi({ example: '65ab1234567890abcdef1234' }),
    name: z.string().openapi({ example: 'John Citizen' }),
    email: z.string().openapi({ example: 'john@example.com' }),
    role: z.string().openapi({ example: 'CITIZEN' }),
    image: z.string().optional().openapi({ example: 'https://...' }),
    phoneNumber: z.string().optional().openapi({ example: '+1234567890' }),
    status: z.string().optional().openapi({ example: 'active' }),
    isVerified: z.boolean().optional().openapi({ example: true }),
  })
  .openapi('UserResponseData');

// POST /user/register
registry.registerPath({
  method: 'post',
  path: '/user/register',
  summary: 'Register User',
  description: 'Registers a new user account with role-specific details.',
  tags: ['User'],
  request: {
    body: {
      content: {
        'application/json': {
          schema: CreateUserRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'User registered successfully. OTP sent to email.',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any().optional(), {
            exampleMessage: 'User created successfully',
          }),
        },
      },
    },
    400: { description: 'Bad request or email already exists', content: { 'application/json': { schema: createErrorResponseSchema() } } },
  },
});

// GET /user/profile
registry.registerPath({
  method: 'get',
  path: '/user/profile',
  summary: 'Get User Profile',
  description: 'Retrieves current authenticated user profile details.',
  tags: ['User'],
  security: [{ [bearerAuth.name]: [] }],
  responses: {
    200: {
      description: 'User profile retrieved successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(UserResponseDataSchema),
        },
      },
    },
    401: { description: 'Unauthorized', content: { 'application/json': { schema: createErrorResponseSchema() } } },
  },
});

// PATCH /user/profile
registry.registerPath({
  method: 'patch',
  path: '/user/profile',
  summary: 'Update User Profile',
  description: 'Updates profile information and avatar image of the current user.',
  tags: ['User'],
  security: [{ [bearerAuth.name]: [] }],
  responses: {
    200: {
      description: 'Profile updated successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(UserResponseDataSchema),
        },
      },
    },
  },
});

// GET /user (Admin list)
registry.registerPath({
  method: 'get',
  path: '/user',
  summary: 'Get All Users (Admin)',
  description: 'Admin endpoint to list all users with role filtering and pagination.',
  tags: ['User'],
  security: [{ [bearerAuth.name]: [] }],
  responses: {
    200: {
      description: 'Users retrieved successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.array(UserResponseDataSchema)),
        },
      },
    },
  },
});
