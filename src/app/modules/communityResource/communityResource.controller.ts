import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { getSingleFilePath } from '../../../shared/getFilePath';
import { CommunityResourceService } from './communityResource.service';

const createResource = catchAsync(async (req: Request, res: Response) => {
  const logo = getSingleFilePath(req.files as Partial<Record<string, Express.Multer.File[]>> | undefined, 'image');
  
  const payload = {
    ...req.body,
    logo,
  };

  const result = await CommunityResourceService.createResourceToDB(payload);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.CREATED,
    message: 'Community Resource created successfully',
    data: result,
  });
});

const getAllResources = catchAsync(async (req: Request, res: Response) => {
  const result = await CommunityResourceService.getAllResourcesFromDB();

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Community Resources retrieved successfully',
    data: result,
  });
});

const getSingleResource = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const result = await CommunityResourceService.getSingleResourceFromDB(id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Community Resource retrieved successfully',
    data: result,
  });
});

const updateResource = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const logo = getSingleFilePath(req.files as Partial<Record<string, Express.Multer.File[]>> | undefined, 'image');

  const payload = {
    ...req.body,
  };
  
  if (logo) {
    payload.logo = logo;
  }

  const result = await CommunityResourceService.updateResourceInDB(id, payload);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Community Resource updated successfully',
    data: result,
  });
});

const deleteResource = catchAsync(async (req: Request, res: Response) => {
  const { id } = req.params;
  const result = await CommunityResourceService.deleteResourceFromDB(id);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Community Resource deleted successfully',
    data: result,
  });
});

export const CommunityResourceController = {
  createResource,
  getAllResources,
  getSingleResource,
  updateResource,
  deleteResource,
};
