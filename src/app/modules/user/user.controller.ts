import { NextFunction, Request, Response } from 'express';
import { StatusCodes } from 'http-status-codes';
import catchAsync from '../../../shared/catchAsync';
import { getSingleFilePath } from '../../../shared/getFilePath';
import sendResponse from '../../../shared/sendResponse';
import { UserService } from './user.service';

const createUser = catchAsync(
  async (req: Request, res: Response, _next: NextFunction) => {
    const { ...userData } = req.body;
    const result = await UserService.createUserToDB(userData);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'User created successfully',
      data: result,
    });
  }
);

const getUserProfile = catchAsync(async (req: Request, res: Response) => {
  const user = req.user;
  const result = await UserService.getUserProfileFromDB(user);

  sendResponse(res, {
    success: true,
    statusCode: StatusCodes.OK,
    message: 'Profile data retrieved successfully',
    data: result,
  });
});

//update profile
const updateProfile = catchAsync(
  async (req: Request, res: Response, _next: NextFunction) => {
    const user = req.user;
    const image = getSingleFilePath(req.files as Partial<Record<string, File[]>> | undefined, 'image');

    const data = {
      image,
      ...req.body,
    };
    const result = await UserService.updateProfileToDB(user, data);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'Profile updated successfully',
      data: result,
    });
  }
);

const createUserByAdmin = catchAsync(
  async (req: Request, res: Response, _next: NextFunction) => {
    const { ...userData } = req.body;
    const result = await UserService.createUserByAdminToDB(userData);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'User created successfully by admin',
      data: result,
    });
  }
);

const getAllUsers = catchAsync(
  async (req: Request, res: Response, _next: NextFunction) => {
    const result = await UserService.getAllUsersFromDB(req.query);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'Users retrieved successfully',
      data: result,
    });
  }
);

const getSingleUser = catchAsync(
  async (req: Request, res: Response, _next: NextFunction) => {
    const result = await UserService.getSingleUserFromDB(req.params.id);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'User retrieved successfully',
      data: result,
    });
  }
);

const updateUser = catchAsync(
  async (req: Request, res: Response, _next: NextFunction) => {
    const image = getSingleFilePath(req.files as Partial<Record<string, File[]>> | undefined, 'image');

    const data = {
      image,
      ...req.body,
    };
    const result = await UserService.updateUserFromDB(req.params.id, data);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'User updated successfully',
      data: result,
    });
  }
);

const deleteUser = catchAsync(
  async (req: Request, res: Response, _next: NextFunction) => {
    const result = await UserService.deleteUserFromDB(req.params.id);

    sendResponse(res, {
      success: true,
      statusCode: StatusCodes.OK,
      message: 'User deleted successfully',
      data: result,
    });
  }
);

export const UserController = {
  createUser,
  getUserProfile,
  updateProfile,
  createUserByAdmin,
  getAllUsers,
  getSingleUser,
  updateUser,
  deleteUser,
};
