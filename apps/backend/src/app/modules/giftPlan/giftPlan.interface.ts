import { Types, Model } from 'mongoose';
import { SUBSCRIPTION_PLAN, PAYMENT_PROVIDER } from '../subscription/subscription.interface';

export type GIFT_CODE_STATUS = 'AVAILABLE' | 'REDEEMED' | 'EXPIRED';

export type IGiftCode = {
  _id?: Types.ObjectId;
  code: string; // e.g. "GOVIA-GIFT-A8F2-99CD"
  batchId: string; // UUID grouping codes purchased in the same transaction
  purchasedBy: Types.ObjectId; // Ref: User (any role)
  purchaserName: string;
  purchaserRole: string;
  purchaserEmail?: string;
  plan: SUBSCRIPTION_PLAN; // 'PREMIUM_MONTHLY' | 'PREMIUM_YEARLY'
  billingCycle: 'MONTHLY' | 'YEARLY';
  durationDays: number; // 30 for Monthly, 365 for Yearly
  pricePerUnit: number;
  totalBatchPrice: number;
  quantity: number;
  status: GIFT_CODE_STATUS;
  redeemedBy?: Types.ObjectId; // Ref: User (recipient)
  redeemedByName?: string;
  redeemedByEmail?: string;
  redeemedByAvatar?: string;
  redeemedAt?: Date;
  expiresAt: Date;
  paymentProvider: PAYMENT_PROVIDER;
  productId: string; // e.g. "govia_gift_monthly_1"
  purchaseToken?: string;
  transactionId?: string;
  createdAt?: Date;
  updatedAt?: Date;
};

export type GiftCodeModel = Model<IGiftCode>;

export type IGiftPackageOption = {
  id: string;
  productId: string;
  title: string;
  plan: SUBSCRIPTION_PLAN;
  billingCycle: 'MONTHLY' | 'YEARLY';
  unitsCount: number;
  durationDays: number;
  price: number;
  unitPrice: number;
  badge?: string;
  discountText?: string;
  description: string;
  features: string[];
};

export type IGiftPurchasePayload = {
  productId: string;
  provider: PAYMENT_PROVIDER;
  purchaseToken?: string;
  transactionId?: string;
};
