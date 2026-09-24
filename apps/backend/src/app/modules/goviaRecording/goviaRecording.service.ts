import { GoviaRecording } from './goviaRecording.model';
import { IGoviaRecording } from './goviaRecording.interface';
import { Types } from 'mongoose';

const createRecording = async (userId: string, payload: Partial<IGoviaRecording>) => {
  const result = await GoviaRecording.create({
    ...payload,
    userId: new Types.ObjectId(userId),
    date: payload.date ? new Date(payload.date) : new Date(),
  });
  return result;
};

const getRecordingsByUser = async (userId: string) => {
  const recordings = await GoviaRecording.find({ userId }).sort({ date: -1 });
  return recordings;
};

export const GoviaRecordingService = {
  createRecording,
  getRecordingsByUser,
};
