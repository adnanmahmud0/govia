import { Model, Types } from 'mongoose';

export type ICommissionSetting = {
  platformCommissionPercent?: number; // e.g. 10 for 10%
  attorneyServiceFee: number; // Monthly fee in USD set by Admin, e.g. 50.00
  bailBondsmanServiceFee: number; // Monthly fee in USD set by Admin, e.g. 30.00
  updatedBy?: Types.ObjectId;
};

export type CommissionSettingModel = Model<ICommissionSetting>;

export type ProviderTransactionType = 'MONTHLY_RETAINER' | 'SERVICE_CHARGE' | 'ENCOUNTER_FEE';
export type ProviderTransactionStatus = 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';

export type IProviderTransaction = {
  transactionId: string;
  citizenId: Types.ObjectId;
  providerId?: Types.ObjectId;
  role: 'ATTORNEY' | 'BAIL_BONDSMAN';
  type: ProviderTransactionType;
  grossAmount: number; // In USD, e.g. 50.00
  platformFee?: number; // In USD, e.g. 50.00
  providerAmount?: number; // In USD (0 since no provider payouts)
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
