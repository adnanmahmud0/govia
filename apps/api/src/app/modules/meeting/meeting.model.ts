import { model, Schema } from 'mongoose';
import { IMeeting, MeetingModel } from './meeting.interface';

const meetingSchema = new Schema<IMeeting, MeetingModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    participantId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    zoomMeetingId: {
      type: String,
      required: true,
    },
    topic: {
      type: String,
      required: true,
    },
    joinUrl: {
      type: String,
      required: true,
    },
    startUrl: {
      type: String,
      required: true,
    },
    password: {
      type: String,
    },
    meetingType: {
      type: String,
      enum: ['INSTANT', 'SCHEDULED', 'EMERGENCY'],
      default: 'INSTANT',
    },
    startTime: {
      type: Date,
    },
    durationMinutes: {
      type: Number,
      default: 30,
    },
    timezone: {
      type: String,
      default: 'UTC',
    },
    agenda: {
      type: String,
    },
    status: {
      type: String,
      enum: ['SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED'],
      default: 'ACTIVE',
    },
    conversationId: {
      type: Schema.Types.ObjectId,
      ref: 'Conversation',
      index: true,
    },
    recordingUrl: {
      type: String,
      default: '',
    },
    recordings: {
      type: [
        {
          id: String,
          fileType: String,
          fileExtension: String,
          fileSize: Number,
          playUrl: String,
          downloadUrl: String,
          recordingType: String,
          recordingStart: String,
          recordingEnd: String,
        },
      ],
      default: [],
    },
    endedAt: {
      type: Date,
    },
    joinedAttorneys: [
      {
        type: Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
  },
  {
    timestamps: true,
  }
);

meetingSchema.index({ startTime: 1, status: 1 });
meetingSchema.index({ userId: 1, status: 1 });
meetingSchema.index({ participantId: 1, status: 1 });

export const Meeting = model<IMeeting, MeetingModel>('Meeting', meetingSchema);
