import { Schema, model } from 'mongoose';
import { IGiftCode, GiftCodeModel } from './giftPlan.interface';

const giftCodeSchema = new Schema<IGiftCode, GiftCodeModel>(
  {
    code: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      uppercase: true,
      index: true,
    },
    batchId: {
      type: String,
      required: true,
      index: true,
    },
    purchasedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    purchaserName: {
      type: String,
      required: true,
      trim: true,
    },
    purchaserRole: {
      type: String,
      required: true,
      trim: true,
    },
    purchaserEmail: {
      type: String,
      trim: true,
    },
    plan: {
      type: String,
      enum: ['PREMIUM_MONTHLY', 'PREMIUM_YEARLY'],
      required: true,
    },
    billingCycle: {
      type: String,
      enum: ['MONTHLY', 'YEARLY'],
      required: true,
    },
    durationDays: {
      type: Number,
      required: true,
      default: 30,
    },
    pricePerUnit: {
      type: Number,
      required: true,
      default: 0,
    },
    totalBatchPrice: {
      type: Number,
      required: true,
      default: 0,
    },
    quantity: {
      type: Number,
      required: true,
      default: 1,
    },
    status: {
      type: String,
      enum: ['AVAILABLE', 'REDEEMED', 'EXPIRED'],
      default: 'AVAILABLE',
      required: true,
      index: true,
    },
    redeemedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    redeemedByName: {
      type: String,
      trim: true,
    },
    redeemedByEmail: {
      type: String,
      trim: true,
    },
    redeemedByAvatar: {
      type: String,
    },
    redeemedAt: {
      type: Date,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
    paymentProvider: {
      type: String,
      enum: ['APPLE_IAP', 'GOOGLE_PLAY', 'STRIPE', 'MANUAL'],
      default: 'MANUAL',
    },
    productId: {
      type: String,
      required: true,
    },
    purchaseToken: {
      type: String,
    },
    transactionId: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Compound indexes for fast querying
giftCodeSchema.index({ purchasedBy: 1, createdAt: -1 });
giftCodeSchema.index({ code: 1, status: 1 });

export const GiftCode = model<IGiftCode, GiftCodeModel>('GiftCode', giftCodeSchema);
