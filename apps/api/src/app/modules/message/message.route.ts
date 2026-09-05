import express, { NextFunction, Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import { USER_ROLES } from '../../../enums/user';
import ApiError from '../../../errors/ApiError';
import auth from '../../middlewares/auth';
import fileUploadHandler from '../../middlewares/fileUploadHandler';
import validateRequest from '../../middlewares/validateRequest';
import { MessageController } from './message.controller';
import { MessageValidation } from './message.validation';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

router.post(
  '/',
  auth(...allRoles),
  fileUploadHandler(),
  (req: Request, res: Response, next: NextFunction) => {
    if (req.body.data && typeof req.body.data === 'string') {
      try {
        const parsed = JSON.parse(req.body.data);
        req.body = { ...req.body, ...parsed };
      } catch {
        return next(
          new ApiError(
            StatusCodes.BAD_REQUEST,
            'Invalid JSON format in data field'
          )
        );
      }
    }

    try {
      MessageValidation.sendMessageZodSchema.parse({ body: req.body });
    } catch (err) {
      return next(err);
    }

    return MessageController.sendMessage(req, res, next);
  }
);

router.get(
  '/search-users',
  auth(...allRoles),
  MessageController.searchUsersForMessaging
);

router.post(
  '/open-chat',
  auth(...allRoles),
  validateRequest(MessageValidation.openChatZodSchema),
  MessageController.openChat
);

router.post(
  '/meeting',
  auth(...allRoles),
  validateRequest(MessageValidation.createMeetingMessageZodSchema),
  MessageController.createMeetingInChat
);

router.get('/:conversationId', auth(...allRoles), MessageController.getMessages);

router.patch(
  '/read/:conversationId',
  auth(...allRoles),
  MessageController.markAsRead
);

export const MessageRoutes = router;
