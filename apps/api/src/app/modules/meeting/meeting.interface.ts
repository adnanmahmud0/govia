import { Model, Types } from 'mongoose';

export type IMeetingRecording = {
  id?: string;
  fileType?: string;
  fileExtension?: string;
  fileSize?: number;
  playUrl?: string;
  downloadUrl?: string;
  recordingType?: string;
  recordingStart?: string;
  recordingEnd?: string;
};

export type IMeeting = {
  userId: Types.ObjectId; // Host / Creator
  participantId?: Types.ObjectId; // Invited user (e.g. Attorney, Bondsman, Citizen)
  conversationId?: Types.ObjectId; // Associated conversation thread if created from chat
  zoomMeetingId: string;
  topic: string;
  joinUrl: string;
  startUrl: string;
  password?: string;
  meetingType: 'INSTANT' | 'SCHEDULED' | 'EMERGENCY';
  startTime?: Date;
  durationMinutes?: number;
  timezone?: string;
  agenda?: string;
  status: 'SCHEDULED' | 'ACTIVE' | 'COMPLETED' | 'CANCELLED';
  joinedAttorneys: Types.ObjectId[];
  recordingUrl?: string;
  recordings?: IMeetingRecording[];
  endedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
};

export type MeetingModel = Model<IMeeting, Record<string, unknown>>;

