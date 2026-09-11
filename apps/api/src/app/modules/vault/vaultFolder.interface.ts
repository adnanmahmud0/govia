import { Model, Types } from 'mongoose';

export type VaultCategory = 'ENCOUNTER' | 'EMERGENCY' | 'CONSULTATION' | 'UPLOADED';

export type IVaultFolder = {
  _id?: Types.ObjectId;
  userId: Types.ObjectId;
  name: string;
  description?: string;
  category: VaultCategory;
  incidentDate: Date;
  location?: string;
  isArchived: boolean;
  createdAt?: Date;
  updatedAt?: Date;
};

export type VaultFolderModel = Model<IVaultFolder, Record<string, unknown>>;
