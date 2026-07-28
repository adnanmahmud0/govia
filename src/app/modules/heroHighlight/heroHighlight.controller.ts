import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { HeroHighlightService } from './heroHighlight.service';

const createHeroHighlight = catchAsync(async (req: Request, res: Response) => {
  const payload = {
    ...req.body,
    uploadedBy: req.user.id, // Assuming req.user is set by auth middleware
  };
  const result = await HeroHighlightService.createHeroHighlightToDB(payload);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.CREATED,
    message: 'Hero Highlight created successfully',
    data: result,
  });
});

const getHeroHighlights = catchAsync(async (req: Request, res: Response) => {
  const result = await HeroHighlightService.getHeroHighlightsFromDB();

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Hero Highlights retrieved successfully',
    data: result,
  });
});

const getSingleHeroHighlight = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const result = await HeroHighlightService.getSingleHeroHighlightFromDB(id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Hero Highlight retrieved successfully',
    data: result,
  });
});

export const HeroHighlightController = {
  createHeroHighlight,
  getHeroHighlights,
  getSingleHeroHighlight,
};
