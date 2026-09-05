import express from 'express';
import { AiAssistantController } from './aiAssistant.controller';
import validateRequest from '../../middlewares/validateRequest';
import { AiAssistantValidation } from './aiAssistant.validation';
import auth from '../../middlewares/auth';
import { USER_ROLES } from '../../../enums/user';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

// Generate a response and create/continue a chat
router.post(
  '/',
  auth(...allRoles),
  validateRequest(AiAssistantValidation.generateResponseZodSchema),
  AiAssistantController.generateResponse
);

// Get the user's chat list
router.get(
  '/chats',
  auth(...allRoles),
  AiAssistantController.getChatList
);

// Get a specific chat's history
router.get(
  '/chats/:id',
  auth(...allRoles),
  AiAssistantController.getChatHistory
);

export const AiAssistantRoutes = router;
