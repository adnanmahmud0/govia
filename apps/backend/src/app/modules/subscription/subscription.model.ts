import { Schema, model } from 'mongoose';
import { ISubscription, SubscriptionModel } from './subscription.interface';

const subscriptionSchema = new Schema<ISubscription, SubscriptionModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    role: {
      type: String,
      default: 'CITIZEN',
    },
    plan: {
      type: String,
      enum: ['FREE', 'PREMIUM_MONTHLY', 'PREMIUM_YEARLY'],
      default: 'FREE',
      required: true,
    },
    status: {
      type: String,
      enum: ['ACTIVE', 'EXPIRED', 'CANCELLED'],
      default: 'ACTIVE',
      required: true,
      index: true,
    },
    billingCycle: {
      type: String,
      enum: ['MONTHLY', 'YEARLY', 'NONE'],
      default: 'NONE',
    },
    price: {
      type: Number,
      default: 0,
    },
    currency: {
      type: String,
      default: 'USD',
    },
    startDate: {
      type: Date,
      default: Date.now,
    },
    endDate: {
      type: Date,
    },
    autoRenew: {
      type: Boolean,
      default: false,
    },
    paymentProvider: {
      type: String,
      enum: ['APPLE_IAP', 'GOOGLE_PLAY', 'STRIPE', 'MANUAL'],
      default: 'MANUAL',
    },
    productId: {
      type: String,
    },
    purchaseToken: {
      type: String,
    },
    originalTransactionId: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Index for active subscription lookups
subscriptionSchema.index({ userId: 1, status: 1 });

export const Subscription = model<ISubscription, SubscriptionModel>(
  'Subscription',
  subscriptionSchema
);
