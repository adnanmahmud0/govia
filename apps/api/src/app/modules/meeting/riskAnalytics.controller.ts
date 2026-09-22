import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { RiskAnalyticsService } from './riskAnalytics.service';

const getRiskAnalytics = catchAsync(async (req: Request, res: Response) => {
  const result = await RiskAnalyticsService.getRiskAnalytics(req.query as any);
  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Risk analytics telemetry retrieved successfully',
    data: result,
  });
});

export const RiskAnalyticsController = {
  getRiskAnalytics,
};
