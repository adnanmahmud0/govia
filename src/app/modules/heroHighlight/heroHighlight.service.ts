import { IHeroHighlight } from './heroHighlight.interface';
import { HeroHighlight } from './heroHighlight.model';
import ApiError from '../../../errors/ApiError';
import { StatusCodes } from 'http-status-codes';

const createHeroHighlightToDB = async (payload: IHeroHighlight) => {
  const result = await HeroHighlight.create(payload);
  return result;
};

const getHeroHighlightsFromDB = async () => {
  const result = await HeroHighlight.find().populate('uploadedBy', 'name email image');
  return result;
};

const getSingleHeroHighlightFromDB = async (id: string) => {
  const result = await HeroHighlight.findById(id).populate('uploadedBy', 'name email image');
  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Hero Highlight not found');
  }
  return result;
};

export const HeroHighlightService = {
  createHeroHighlightToDB,
  getHeroHighlightsFromDB,
  getSingleHeroHighlightFromDB,
};
