import { ICommunityResource } from './communityResource.interface';
import { CommunityResource } from './communityResource.model';
import ApiError from '../../../errors/ApiError';
import { StatusCodes } from 'http-status-codes';

const createResourceToDB = async (payload: ICommunityResource) => {
  const result = await CommunityResource.create(payload);
  return result;
};

const getAllResourcesFromDB = async () => {
  const result = await CommunityResource.find();
  return result;
};

const getSingleResourceFromDB = async (id: string) => {
  const result = await CommunityResource.findById(id);
  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Community Resource not found');
  }
  return result;
};

const updateResourceInDB = async (id: string, payload: Partial<ICommunityResource>) => {
  const result = await CommunityResource.findByIdAndUpdate(id, payload, { new: true });
  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Community Resource not found');
  }
  return result;
};

const deleteResourceFromDB = async (id: string) => {
  const result = await CommunityResource.findByIdAndDelete(id);
  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Community Resource not found');
  }
  return result;
};

export const CommunityResourceService = {
  createResourceToDB,
  getAllResourcesFromDB,
  getSingleResourceFromDB,
  updateResourceInDB,
  deleteResourceFromDB,
};
