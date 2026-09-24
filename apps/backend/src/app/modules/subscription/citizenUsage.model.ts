import { Schema, model } from 'mongoose';
import { ICitizenUsage, CitizenUsageModel } from './subscription.interface';

const citizenUsageSchema = new Schema<ICitizenUsage, CitizenUsageModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    yearMonth: {
      type: String,
      required: true,
      index: true,
    },
    meetingCount: {
      type: Number,
      default: 0,
    },
    lastMeetingAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index so each user has at most one usage record per calendar month
citizenUsageSchema.index({ userId: 1, yearMonth: 1 }, { unique: true });

export const CitizenUsage = model<ICitizenUsage, CitizenUsageModel>(
  'CitizenUsage',
  citizenUsageSchema
);
