import { Model, Types } from 'mongoose';

export type IGoviaRecording = {
  userId: Types.ObjectId;
  title: string;
  description: string;
  location: string;
  date: Date;
  recordingUrl?: string;
  createdAt?: Date;
  updatedAt?: Date;
};

export type GoviaRecordingModel = Model<IGoviaRecording, Record<string, unknown>>;
