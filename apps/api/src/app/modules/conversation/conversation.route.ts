import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import validateRequest from '../../middlewares/validateRequest';
import { ConversationController } from './conversation.controller';
import { ConversationValidation } from './conversation.validation';

const router = express.Router();

// Allow all authenticated roles
const allRoles = Object.values(USER_ROLES);

router.post(
  '/',
  auth(...allRoles),
  validateRequest(ConversationValidation.createConversationZodSchema),
  ConversationController.createOrGetConversation
);

router.get('/', auth(...allRoles), ConversationController.getUserConversations);

router.get(
  '/search-users',
  auth(...allRoles),
  ConversationController.searchUsersForMessaging
);

router.get('/:id', auth(...allRoles), ConversationController.getSingleConversation);

export const ConversationRoutes = router;
