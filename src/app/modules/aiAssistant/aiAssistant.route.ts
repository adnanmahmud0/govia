import express from 'express';
import { AiAssistantController } from './aiAssistant.controller';
import validateRequest from '../../middlewares/validateRequest';
import { AiAssistantValidation } from './aiAssistant.validation';
import auth from '../../middlewares/auth';
import { USER_ROLES } from '../../../enums/user';

const router = express.Router();

// Generate a response and create/continue a chat
router.post(
  '/',
  auth(USER_ROLES.USER, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  validateRequest(AiAssistantValidation.generateResponseZodSchema),
  AiAssistantController.generateResponse
);

// Get the user's chat list
router.get(
  '/chats',
  auth(USER_ROLES.USER, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  AiAssistantController.getChatList
);

// Get a specific chat's history
router.get(
  '/chats/:id',
  auth(USER_ROLES.USER, USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  AiAssistantController.getChatHistory
);

export const AiAssistantRoutes = router;
