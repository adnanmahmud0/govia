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
  roomName: string;
  zoomMeetingId?: string;
  topic: string;
  joinUrl?: string;
  startUrl?: string;
  password?: string;
  meetingType: 'INSTANT' | 'SCHEDULED' | 'EMERGENCY';
  category?: 'ENCOUNTER' | 'EMERGENCY' | 'CONSULTATION';
  vaultFolderId?: Types.ObjectId;
  startTime?: Date;
  durationMinutes?: number;
  timezone?: string;
  agenda?: string;
  status: 'SCHEDULED' | 'ACTIVE' | 'COMPLETED' | 'CANCELLED';
  joinedAttorneys: Types.ObjectId[];
  joinedParticipants?: Types.ObjectId[];
  recordingUrl?: string;
  recordings?: IMeetingRecording[];
  sessionName?: string;
  egressId?: string;
  livekitToken?: string;
  token?: string;
  livekitUrl?: string;
  endedAt?: Date;
  latitude?: number;
  longitude?: number;
  locationAddress?: string;
  createdAt?: Date;
  updatedAt?: Date;
};

export type MeetingModel = Model<IMeeting, Record<string, unknown>>;

