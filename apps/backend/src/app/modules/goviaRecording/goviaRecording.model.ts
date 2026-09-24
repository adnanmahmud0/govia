import { model, Schema } from 'mongoose';
import { GoviaRecordingModel, IGoviaRecording } from './goviaRecording.interface';

const goviaRecordingSchema = new Schema<IGoviaRecording, GoviaRecordingModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    location: {
      type: String,
      required: true,
    },
    date: {
      type: Date,
      required: true,
      default: Date.now,
    },
    recordingUrl: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

export const GoviaRecording = model<IGoviaRecording, GoviaRecordingModel>(
  'GoviaRecording',
  goviaRecordingSchema
);
