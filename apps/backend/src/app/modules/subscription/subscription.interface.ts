import { Types, Model } from 'mongoose';

export type SUBSCRIPTION_PLAN = 'FREE' | 'PREMIUM_MONTHLY' | 'PREMIUM_YEARLY';
export type SUBSCRIPTION_STATUS = 'ACTIVE' | 'EXPIRED' | 'CANCELLED';
export type BILLING_CYCLE = 'MONTHLY' | 'YEARLY' | 'NONE';
export type PAYMENT_PROVIDER = 'APPLE_IAP' | 'GOOGLE_PLAY' | 'STRIPE' | 'MANUAL';

export type ISubscription = {
  _id?: Types.ObjectId;
  userId: Types.ObjectId;
  role: string;
  plan: SUBSCRIPTION_PLAN;
  status: SUBSCRIPTION_STATUS;
  billingCycle: BILLING_CYCLE;
  price: number;
  currency: string;
  startDate: Date;
  endDate?: Date;
  autoRenew: boolean;
  paymentProvider: PAYMENT_PROVIDER;
  productId?: string;
  purchaseToken?: string;
  originalTransactionId?: string;
  createdAt?: Date;
  updatedAt?: Date;
};

export type SubscriptionModel = Model<ISubscription>;

export type ICitizenUsage = {
  _id?: Types.ObjectId;
  userId: Types.ObjectId;
  yearMonth: string; // Format: 'YYYY-MM'
  meetingCount: number;
  lastMeetingAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
};

export type CitizenUsageModel = Model<ICitizenUsage>;
