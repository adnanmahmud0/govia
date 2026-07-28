import { Model, Types } from 'mongoose';

export type IMeeting = {
  userId: Types.ObjectId;
  zoomMeetingId: string;
  topic: string;
  joinUrl: string;
  startUrl: string;
  password?: string;
  status: 'ACTIVE' | 'COMPLETED';
  joinedAttorneys: Types.ObjectId[];
  createdAt?: Date;
  updatedAt?: Date;
};

export type MeetingModel = Model<IMeeting, Record<string, unknown>>;
