import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import { NotificationController } from './notification.controller';

const router = express.Router();
const allRoles = Object.values(USER_ROLES);

// GET /notification or /notification/my-notifications
router.get('/', auth(...allRoles), NotificationController.getMyNotifications);
router.get('/my-notifications', auth(...allRoles), NotificationController.getMyNotifications);

// Mark single notification as read (supports both PATCH and POST)
router.patch('/:id/read', auth(...allRoles), NotificationController.markAsRead);
router.post('/:id/read', auth(...allRoles), NotificationController.markAsRead);

// Mark all as read (supports both PATCH and POST)
router.patch('/read-all', auth(...allRoles), NotificationController.markAllAsRead);
router.post('/read-all', auth(...allRoles), NotificationController.markAllAsRead);

// Delete notification
router.delete('/:id', auth(...allRoles), NotificationController.deleteNotification);

export const NotificationRoutes = router;
