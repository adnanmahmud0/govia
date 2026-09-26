import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { GiftPlanService } from './giftPlan.service';

const getGiftPackages = catchAsync(async (_req: Request, res: Response) => {
  const result = await GiftPlanService.getGiftPackages();

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Gift packages retrieved successfully',
    data: result,
  });
});

const purchaseGiftPackage = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const userRole = req.user?.role;

  const result = await GiftPlanService.purchaseGiftPackage(
    userId,
    userRole,
    req.body
  );

  sendResponse(res, {
    statusCode: StatusCodes.CREATED,
    success: true,
    message: 'Gift package purchased and codes generated successfully',
    data: result,
  });
});

const getMyPurchasedGifts = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;

  const result = await GiftPlanService.getMyPurchasedGifts(userId);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Purchased gift codes retrieved successfully',
    data: result,
  });
});

const validateGiftCode = catchAsync(async (req: Request, res: Response) => {
  const { code } = req.body;

  const result = await GiftPlanService.validateGiftCode(code);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Gift code is valid',
    data: result,
  });
});

const redeemGiftCode = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const userRole = req.user?.role;
  const { code } = req.body;

  const result = await GiftPlanService.redeemGiftCode(userId, userRole, code);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: result.message,
    data: result,
  });
});

export const GiftPlanController = {
  getGiftPackages,
  purchaseGiftPackage,
  getMyPurchasedGifts,
  validateGiftCode,
  redeemGiftCode,
};
