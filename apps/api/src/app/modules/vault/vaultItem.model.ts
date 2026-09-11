import { model, Schema } from 'mongoose';
import { IVaultItem, VaultItemModel } from './vaultItem.interface';

const vaultItemSchema = new Schema<IVaultItem, VaultItemModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    folderId: {
      type: Schema.Types.ObjectId,
      ref: 'VaultFolder',
      required: true,
      index: true,
    },
    title: {
      type: String,
      default: '',
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    category: {
      type: String,
      enum: ['ENCOUNTER', 'EMERGENCY', 'CONSULTATION', 'UPLOADED'],
      default: 'UPLOADED',
      index: true,
    },
    subCategory: {
      type: String,
      default: '',
    },
    importance: {
      type: String,
      enum: ['CRITICAL', 'HIGH', 'SUPPORTING', 'GENERAL'],
      default: 'GENERAL',
      index: true,
    },
    fileType: {
      type: String,
      enum: ['VIDEO', 'AUDIO', 'IMAGE', 'DOCUMENT', 'RECORDING'],
      required: true,
      index: true,
    },
    fileUrl: {
      type: String,
      required: true,
    },
    thumbnailUrl: {
      type: String,
      default: '',
    },
    fileSize: {
      type: Number,
      default: 0,
    },
    mimeType: {
      type: String,
      default: '',
    },
    duration: {
      type: String,
      default: '',
    },
    meetingId: {
      type: Schema.Types.ObjectId,
      ref: 'Meeting',
    },
    goviaRecordingId: {
      type: Schema.Types.ObjectId,
      ref: 'GoviaRecording',
    },
  },
  {
    timestamps: true,
  }
);

export const VaultItem = model<IVaultItem, VaultItemModel>(
  'VaultItem',
  vaultItemSchema
);
