import { Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import sendResponse from '../../../shared/sendResponse';
import { VaultService } from './vault.service';

const createFolder = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const result = await VaultService.createFolder(userId, req.body);

  sendResponse(res, {
    statusCode: StatusCodes.CREATED,
    success: true,
    message: 'Vault folder created successfully',
    data: result,
  });
});

const getUserFolders = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const result = await VaultService.getUserFolders(userId, req.query as any);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Vault folders retrieved successfully',
    data: result,
  });
});

const getFolderDetails = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const { id } = req.params;
  const result = await VaultService.getFolderDetails(userId, id);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Vault folder details retrieved successfully',
    data: result,
  });
});

const updateFolder = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const { id } = req.params;
  const result = await VaultService.updateFolder(userId, id, req.body);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Vault folder updated successfully',
    data: result,
  });
});

const deleteFolder = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const { id } = req.params;
  const result = await VaultService.deleteFolder(userId, id);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Vault folder and evidence items deleted successfully',
    data: result,
  });
});

const uploadEvidence = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const { folderId, title, description, category } = req.body;
  const files = req.files as any;

  const result = await VaultService.uploadEvidence(userId, folderId, files, {
    title,
    description,
    category,
  });

  sendResponse(res, {
    statusCode: StatusCodes.CREATED,
    success: true,
    message: 'Evidence files uploaded successfully to vault',
    data: result,
  });
});

const linkMeetingToFolder = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const result = await VaultService.linkMeetingToFolder(userId, req.body);

  sendResponse(res, {
    statusCode: StatusCodes.CREATED,
    success: true,
    message: 'Meeting recording linked to vault folder successfully',
    data: result,
  });
});

const deleteItem = catchAsync(async (req: Request, res: Response) => {
  const userId = req.user.id;
  const { id } = req.params;
  const result = await VaultService.deleteItem(userId, id);

  sendResponse(res, {
    statusCode: StatusCodes.OK,
    success: true,
    message: 'Evidence item removed from vault successfully',
    data: result,
  });
});

export const VaultController = {
  createFolder,
  getUserFolders,
  getFolderDetails,
  updateFolder,
  deleteFolder,
  uploadEvidence,
  linkMeetingToFolder,
  deleteItem,
};
