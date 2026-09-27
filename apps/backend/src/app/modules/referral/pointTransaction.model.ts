import { Schema, model } from 'mongoose';
import { IPointTransaction, PointTransactionModel } from './referral.interface';

const pointTransactionSchema = new Schema<IPointTransaction, PointTransactionModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    type: {
      type: String,
      enum: [
        'REFERRAL_BONUS',
        'WELCOME_BONUS',
        'REDEEM_SUBSCRIPTION',
        'REDEEM_GIFT_PASS',
        'REDEEM_PROVIDER_CREDIT',
        'ADMIN_ADJUSTMENT',
      ],
      required: true,
    },
    points: {
      type: Number,
      required: true,
    },
    balanceAfter: {
      type: Number,
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    metadata: {
      type: Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

export const PointTransaction = model<IPointTransaction, PointTransactionModel>(
  'PointTransaction',
  pointTransactionSchema
);
