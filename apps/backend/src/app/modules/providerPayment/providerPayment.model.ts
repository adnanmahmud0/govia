import { Schema, model } from 'mongoose';
import {
  CommissionSettingModel,
  ICommissionSetting,
  IProviderTransaction,
  ProviderTransactionModel,
} from './providerPayment.interface';

const commissionSettingSchema = new Schema<ICommissionSetting, CommissionSettingModel>(
  {
    attorneyServiceFee: {
      type: Number,
      default: 50,
      min: 0,
      required: true,
    },
    bailBondsmanServiceFee: {
      type: Number,
      default: 30,
      min: 0,
      required: true,
    },
    platformCommissionPercent: {
      type: Number,
      default: 10,
      min: 0,
      max: 100,
      required: false,
    },
    updatedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
  },
  {
    timestamps: true,
  }
);

export const CommissionSetting = model<ICommissionSetting, CommissionSettingModel>(
  'CommissionSetting',
  commissionSettingSchema
);

const providerTransactionSchema = new Schema<IProviderTransaction, ProviderTransactionModel>(
  {
    transactionId: {
      type: String,
      required: true,
      unique: true,
    },
    citizenId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    providerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: false,
    },
    role: {
      type: String,
      enum: ['ATTORNEY', 'BAIL_BONDSMAN'],
      required: true,
    },
    type: {
      type: String,
      enum: ['MONTHLY_RETAINER', 'SERVICE_CHARGE', 'ENCOUNTER_FEE'],
      default: 'SERVICE_CHARGE',
      required: true,
    },
    grossAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    platformFee: {
      type: Number,
      default: 0,
      min: 0,
    },
    providerAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    currency: {
      type: String,
      default: 'usd',
    },
    status: {
      type: String,
      enum: ['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED'],
      default: 'PENDING',
      required: true,
    },
    stripeSessionId: { type: String },
    stripePaymentIntentId: { type: String },
    stripeTransferId: { type: String },
    meetingId: {
      type: Schema.Types.ObjectId,
      ref: 'Meeting',
    },
    periodStart: { type: Date },
    periodEnd: { type: Date },
    failureReason: { type: String },
  },
  {
    timestamps: true,
  }
);

providerTransactionSchema.index({ citizenId: 1, providerId: 1 });
providerTransactionSchema.index({ status: 1 });
providerTransactionSchema.index({ stripeSessionId: 1 });

export const ProviderTransaction = model<IProviderTransaction, ProviderTransactionModel>(
  'ProviderTransaction',
  providerTransactionSchema
);
