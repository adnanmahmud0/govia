import { Model, Types } from 'mongoose';

export type StorageProviderType =
  | 'AWS_S3'
  | 'CLOUDFLARE_R2'
  | 'DIGITALOCEAN_SPACES'
  | 'MINIO'
  | 'CUSTOM';

export type IStorageSetting = {
  provider: StorageProviderType;
  bucket: string;
  region: string;
  accessKey: string;
  secretKey: string;
  endpoint?: string;
  publicDomain?: string;
  livekitUrl?: string;
  livekitApiKey?: string;
  livekitApiSecret?: string;
  autoRecordMeetings: boolean;
  isActive: boolean;
  updatedBy?: Types.ObjectId;
  createdAt?: Date;
  updatedAt?: Date;
};

export type StorageSettingModel = Model<IStorageSetting, Record<string, unknown>>;
