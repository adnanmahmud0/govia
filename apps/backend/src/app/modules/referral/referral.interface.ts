import { Types, Model } from 'mongoose';
import { IUser } from '../user/user.interface';

export type REFERRAL_STATUS = 'COMPLETED' | 'PENDING' | 'REVERTED';

export type IReferral = {
  _id?: Types.ObjectId;
  referrerId: Types.ObjectId | IUser;
  refereeId: Types.ObjectId | IUser;
  referralCode: string;
  pointsAwardedToReferrer: number;
  pointsAwardedToReferee: number;
  status: REFERRAL_STATUS;
  createdAt?: Date;
  updatedAt?: Date;
};

export type ReferralModel = Model<IReferral>;

export type POINT_TRANSACTION_TYPE =
  | 'REFERRAL_BONUS'
  | 'WELCOME_BONUS'
  | 'REDEEM_SUBSCRIPTION'
  | 'REDEEM_GIFT_PASS'
  | 'REDEEM_PROVIDER_CREDIT'
  | 'ADMIN_ADJUSTMENT';

export type IPointTransaction = {
  _id?: Types.ObjectId;
  userId: Types.ObjectId | IUser;
  type: POINT_TRANSACTION_TYPE;
  points: number; // positive = credit, negative = debit
  balanceAfter: number;
  title: string;
  description: string;
  metadata?: Record<string, unknown>;
  createdAt?: Date;
  updatedAt?: Date;
};

export type PointTransactionModel = Model<IPointTransaction>;

export type IReferralSummary = {
  referralCode: string;
  referralLink: string;
  pointsBalance: number;
  lifetimePoints: number;
  referralCount: number;
  tier: 'BRONZE' | 'SILVER' | 'GOLD' | 'PLATINUM';
  tierNextTarget: number;
};

export type IRewardCatalogItem = {
  id: string;
  title: string;
  description: string;
  pointsCost: number;
  category: 'SUBSCRIPTION' | 'GIFT' | 'CREDIT';
  badge: string;
  isPopular?: boolean;
  actionType: 'ACTIVATE_SUBSCRIPTION' | 'GENERATE_GIFT_PASS' | 'GENERATE_PROVIDER_CREDIT';
};
