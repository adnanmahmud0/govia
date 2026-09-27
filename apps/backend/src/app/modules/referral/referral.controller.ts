import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { ReferralService } from './referral.service';

const getReferralSummary = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await ReferralService.getReferralSummary(userId);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Referral summary retrieved successfully',
    data: result,
  });
});

const getReferralHistory = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await ReferralService.getReferralHistory(userId, req.query);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Referral history retrieved successfully',
    data: result.data,
    pagination: result.meta,
  });
});

const getRewardsCatalog = catchAsync(async (_req: Request, res: Response) => {
  const result = await ReferralService.getRewardsCatalog();

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Rewards catalog retrieved successfully',
    data: result,
  });
});

const redeemReward = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const { rewardId } = req.body;

  const result = await ReferralService.redeemReward(userId, rewardId);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: result.message,
    data: result.details,
  });
});

const getPointTransactions = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user?.id;
  const result = await ReferralService.getPointTransactions(userId, req.query);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Point transactions retrieved successfully',
    data: result.data,
    pagination: result.meta,
  });
});

const getAdminReferralOverview = catchAsync(async (_req: Request, res: Response) => {
  const result = await ReferralService.getAdminReferralOverview();

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Admin referral overview retrieved successfully',
    data: result,
  });
});

export const ReferralController = {
  getReferralSummary,
  getReferralHistory,
  getRewardsCatalog,
  redeemReward,
  getPointTransactions,
  getAdminReferralOverview,
};
