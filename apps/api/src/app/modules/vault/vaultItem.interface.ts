import { Model, Types } from 'mongoose';
import { VaultCategory } from './vaultFolder.interface';

export type VaultItemType = 'VIDEO' | 'AUDIO' | 'IMAGE' | 'DOCUMENT' | 'RECORDING';

export type IVaultItem = {
  _id?: Types.ObjectId;
  userId: Types.ObjectId;
  folderId: Types.ObjectId;
  title?: string;
  description?: string;
  category: VaultCategory;
  fileType: VaultItemType;
  fileUrl: string;
  thumbnailUrl?: string;
  fileSize?: number;
  mimeType?: string;
  duration?: string;
  meetingId?: Types.ObjectId;
  goviaRecordingId?: Types.ObjectId;
  createdAt?: Date;
  updatedAt?: Date;
};

export type VaultItemModel = Model<IVaultItem, Record<string, unknown>>;
