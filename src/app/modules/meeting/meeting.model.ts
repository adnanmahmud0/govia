import { model, Schema } from 'mongoose';
import { IMeeting, MeetingModel } from './meeting.interface';

const meetingSchema = new Schema<IMeeting, MeetingModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
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
    status: {
      type: String,
      enum: ['ACTIVE', 'COMPLETED'],
      default: 'ACTIVE',
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

export const Meeting = model<IMeeting, MeetingModel>('Meeting', meetingSchema);
