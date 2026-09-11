import { model, Schema } from 'mongoose';
import { IVaultFolder, VaultFolderModel } from './vaultFolder.interface';

const vaultFolderSchema = new Schema<IVaultFolder, VaultFolderModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
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
      default: 'ENCOUNTER',
      index: true,
    },
    incidentDate: {
      type: Date,
      default: Date.now,
    },
    location: {
      type: String,
      default: '',
      trim: true,
    },
    isArchived: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

export const VaultFolder = model<IVaultFolder, VaultFolderModel>(
  'VaultFolder',
  vaultFolderSchema
);
