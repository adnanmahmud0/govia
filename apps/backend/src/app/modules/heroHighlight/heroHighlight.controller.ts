import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { HeroHighlightService } from './heroHighlight.service';

const createHeroHighlight = catchAsync(async (req: Request, res: Response) => {
  const payload = {
    ...req.body,
    uploadedBy: req.user.id,
  };
  const result = await HeroHighlightService.createHeroHighlightToDB(payload);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.CREATED,
    message: 'Hero Highlight commendation submitted successfully',
    data: result,
  });
});

const getOfficers = catchAsync(async (req: Request, res: Response) => {
  const searchQuery = req.query.query ? String(req.query.query) : undefined;
  const result = await HeroHighlightService.getOfficersFromDB(searchQuery);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Officers retrieved successfully',
    data: result,
  });
});

const lookupOfficer = catchAsync(async (req: Request, res: Response) => {
  const { identifier } = req.params;
  const result = await HeroHighlightService.lookupOfficerByIdentifier(identifier);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Officer profile retrieved successfully',
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

const toggleSalute = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const userId = req.user.id;
  const result = await HeroHighlightService.toggleSaluteInDB(id, userId);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: result.saluted ? 'Hero saluted!' : 'Salute removed',
    data: result,
  });
});

export const HeroHighlightController = {
  createHeroHighlight,
  getOfficers,
  lookupOfficer,
  getHeroHighlights,
  getSingleHeroHighlight,
  toggleSalute,
};
