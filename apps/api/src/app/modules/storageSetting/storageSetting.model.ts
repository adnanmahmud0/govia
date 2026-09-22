import { Schema, model } from 'mongoose';
import { IStorageSetting, StorageSettingModel } from './storageSetting.interface';

const storageSettingSchema = new Schema<IStorageSetting, StorageSettingModel>(
  {
    provider: {
      type: String,
      enum: ['AWS_S3', 'CLOUDFLARE_R2', 'DIGITALOCEAN_SPACES', 'MINIO', 'CUSTOM'],
      default: 'AWS_S3',
      required: true,
    },
    bucket: {
      type: String,
      default: '',
    },
    region: {
      type: String,
      default: 'us-east-1',
    },
    accessKey: {
      type: String,
      default: '',
    },
    secretKey: {
      type: String,
      default: '',
    },
    endpoint: {
      type: String,
      default: '',
    },
    publicDomain: {
      type: String,
      default: '',
    },
    livekitUrl: {
      type: String,
      default: '',
    },
    livekitApiKey: {
      type: String,
      default: '',
    },
    livekitApiSecret: {
      type: String,
      default: '',
    },
    autoRecordMeetings: {
      type: Boolean,
      default: true,
    },
    isActive: {
      type: Boolean,
      default: true,
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

export const StorageSetting = model<IStorageSetting, StorageSettingModel>(
  'StorageSetting',
  storageSettingSchema
);
