import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { NotificationService } from './notification.service';

const getMyNotifications = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const userRole = req.user?.role || 'CITIZEN';
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 20;

  const result = await NotificationService.getNotifications(
    userId,
    userRole,
    page,
    limit
  );

  res.status(StatusCodes.OK).json({
    success: true,
    message: 'Notifications fetched successfully',
    data: result.data,
    meta: result.meta,
    pagination: {
      page: result.meta.page,
      limit: result.meta.limit,
      total: result.meta.total,
      totalPage: Math.ceil(result.meta.total / result.meta.limit),
    },
  });
});

const markAsRead = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;

  const result = await NotificationService.markAsRead(userId, id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Notification marked as read',
    data: result,
  });
});

const markAllAsRead = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;

  const result = await NotificationService.markAllAsRead(userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'All notifications marked as read',
    data: result,
  });
});

const deleteNotification = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { id } = req.params;

  const result = await NotificationService.deleteNotification(userId, id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Notification deleted successfully',
    data: result,
  });
});

export const NotificationController = {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
};
