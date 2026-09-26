import { Model, Types } from 'mongoose';

export type ICommissionSetting = {
  platformCommissionPercent: number; // e.g. 10 for 10%
  updatedBy?: Types.ObjectId;
};

export type CommissionSettingModel = Model<ICommissionSetting>;

export type ProviderTransactionType = 'MONTHLY_RETAINER' | 'ENCOUNTER_FEE';
export type ProviderTransactionStatus = 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';

export type IProviderTransaction = {
  transactionId: string;
  citizenId: Types.ObjectId;
  providerId: Types.ObjectId;
  role: 'ATTORNEY' | 'BAIL_BONDSMAN';
  type: ProviderTransactionType;
  grossAmount: number; // In USD, e.g. 50.00
  platformFee: number; // In USD, e.g. 5.00
  providerAmount: number; // In USD, e.g. 45.00
  currency: string;
  status: ProviderTransactionStatus;
  stripeSessionId?: string;
  stripePaymentIntentId?: string;
  stripeTransferId?: string;
  meetingId?: Types.ObjectId;
  periodStart?: Date;
  periodEnd?: Date;
  failureReason?: string;
  createdAt?: Date;
  updatedAt?: Date;
};

export type ProviderTransactionModel = Model<IProviderTransaction>;
