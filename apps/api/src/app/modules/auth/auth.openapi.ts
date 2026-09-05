import { z } from 'zod';
import {
  bearerAuth,
  createErrorResponseSchema,
  createSuccessResponseSchema,
  registry,
} from '../../../docs/openapi-registry';
import { AuthValidation } from './auth.validation';

// Request Schemas
export const LoginRequestSchema = AuthValidation.createLoginZodSchema.shape.body.openapi({
  description: 'User login payload with role',
  example: {
    email: 'user@example.com',
    role: 'CITIZEN',
    password: 'Password123!',
  },
});

export const VerifyEmailRequestSchema = AuthValidation.createVerifyEmailZodSchema.shape.body.openapi({
  description: 'Email OTP verification payload',
  example: {
    email: 'user@example.com',
    role: 'CITIZEN',
    oneTimeCode: 123456,
  },
});

export const ForgetPasswordRequestSchema = AuthValidation.createForgetPasswordZodSchema.shape.body.openapi({
  description: 'Request password reset OTP',
  example: {
    email: 'user@example.com',
    role: 'CITIZEN',
  },
});

export const ResetPasswordRequestSchema = AuthValidation.createResetPasswordZodSchema.shape.body.openapi({
  description: 'Reset password payload using reset token in header',
  example: {
    newPassword: 'NewPassword123!',
    confirmPassword: 'NewPassword123!',
  },
});

export const ChangePasswordRequestSchema = AuthValidation.createChangePasswordZodSchema.shape.body.openapi({
  description: 'Change password payload for authenticated user',
  example: {
    currentPassword: 'OldPassword123!',
    newPassword: 'NewPassword123!',
    confirmPassword: 'NewPassword123!',
  },
});

// Response Schemas
export const LoginResponseDataSchema = z
  .object({
    accessToken: z.string().openapi({ example: 'eyJhbGciOiJIUzI1NiIsIn...' }),
    refreshToken: z.string().openapi({ example: 'eyJhbGciOiJIUzI1NiIsIn...' }),
  })
  .openapi('LoginResponseData');

// Route Registrations
registry.registerPath({
  method: 'post',
  path: '/auth/login',
  summary: 'User Login',
  description: 'Authenticates a user with email, role, and password, returning JWT access and refresh tokens.',
  tags: ['Auth'],
  request: {
    body: {
      content: {
        'application/json': {
          schema: LoginRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Logged in successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(LoginResponseDataSchema, {
            exampleMessage: 'User logged in successfully',
          }),
        },
      },
    },
    400: { description: 'Bad request or validation error', content: { 'application/json': { schema: createErrorResponseSchema() } } },
    404: { description: 'User not found', content: { 'application/json': { schema: createErrorResponseSchema() } } },
  },
});

registry.registerPath({
  method: 'post',
  path: '/auth/verify-email',
  summary: 'Verify Email with OTP',
  description: 'Verifies email address using the one-time code sent to the user.',
  tags: ['Auth'],
  request: {
    body: {
      content: {
        'application/json': {
          schema: VerifyEmailRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Email verified successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any().optional(), {
            exampleMessage: 'Email verified successfully',
          }),
        },
      },
    },
    400: { description: 'Invalid or expired OTP', content: { 'application/json': { schema: createErrorResponseSchema() } } },
  },
});

registry.registerPath({
  method: 'post',
  path: '/auth/forget-password',
  summary: 'Request Password Reset OTP',
  description: 'Sends a password recovery verification OTP to the user email.',
  tags: ['Auth'],
  request: {
    body: {
      content: {
        'application/json': {
          schema: ForgetPasswordRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'OTP sent successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any().optional(), {
            exampleMessage: 'Please check your email. OTP has been sent.',
          }),
        },
      },
    },
  },
});

registry.registerPath({
  method: 'post',
  path: '/auth/reset-password',
  summary: 'Reset Password',
  description: 'Resets user password using the token provided in the Authorization header.',
  tags: ['Auth'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: ResetPasswordRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Password reset successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any().optional(), {
            exampleMessage: 'Password reset successfully',
          }),
        },
      },
    },
  },
});

registry.registerPath({
  method: 'post',
  path: '/auth/change-password',
  summary: 'Change Password',
  description: 'Changes password for the currently authenticated user.',
  tags: ['Auth'],
  security: [{ [bearerAuth.name]: [] }],
  request: {
    body: {
      content: {
        'application/json': {
          schema: ChangePasswordRequestSchema,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Password changed successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(z.any().optional(), {
            exampleMessage: 'Password changed successfully',
          }),
        },
      },
    },
  },
});

registry.registerPath({
  method: 'post',
  path: '/auth/refresh',
  summary: 'Refresh Access Token',
  description: 'Uses refresh token to generate a fresh JWT access token.',
  tags: ['Auth'],
  responses: {
    200: {
      description: 'Access token refreshed successfully',
      content: {
        'application/json': {
          schema: createSuccessResponseSchema(LoginResponseDataSchema),
        },
      },
    },
  },
});
