import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { SubscriptionService } from './subscription.service';

const getMySubscriptionStatus = catchAsync(
  async (req: Request, res: Response) => {
    const userId = req.user?.id;
    const userRole = req.user?.role;

    const result = await SubscriptionService.getUserSubscriptionStatus(
      userId,
      userRole
    );

    sendResponse(res, {
      statusCode: StatusCodes.OK,
      success: true,
      message: 'Subscription status retrieved successfully',
      data: result,
    });
  }
);

const getAvailablePlans = catchAsync(async (_req: Request, res: Response) => {
  const result = await SubscriptionService.getAvailablePlans();

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Subscription plans retrieved successfully',
    data: result,
  });
});

const verifyIAP = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const userRole = req.user?.role;

  const result = await SubscriptionService.verifyAndSubscribeIAP(
    userId,
    userRole,
    req.body
  );

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'In-App Purchase verified and subscription activated successfully',
    data: result,
  });
});

const subscribeManual = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const userRole = req.user?.role;
  const { plan, paymentProvider } = req.body;

  const result = await SubscriptionService.subscribeManual(
    userId,
    userRole,
    plan,
    paymentProvider
  );

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Subscription updated successfully',
    data: result,
  });
});

const cancelSubscription = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;

  const result = await SubscriptionService.cancelSubscription(userId);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Subscription auto-renewal cancelled successfully',
    data: result,
  });
});

export const SubscriptionController = {
  getMySubscriptionStatus,
  getAvailablePlans,
  verifyIAP,
  subscribeManual,
  cancelSubscription,
};
