import { Schema, model } from 'mongoose';
import { IReferral, ReferralModel } from './referral.interface';

const referralSchema = new Schema<IReferral, ReferralModel>(
  {
    referrerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    refereeId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
      unique: true, // A user can only be referred once
    },
    referralCode: {
      type: String,
      required: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    pointsAwardedToReferrer: {
      type: Number,
      required: true,
      default: 250,
    },
    pointsAwardedToReferee: {
      type: Number,
      required: true,
      default: 100,
    },
    status: {
      type: String,
      enum: ['COMPLETED', 'PENDING', 'REVERTED'],
      default: 'COMPLETED',
    },
  },
  {
    timestamps: true,
  }
);

export const Referral = model<IReferral, ReferralModel>('Referral', referralSchema);
