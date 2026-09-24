import { Schema, model } from 'mongoose';
import { CommunityResourceModel, ICommunityResource } from './communityResource.interface';

const communityResourceSchema = new Schema<ICommunityResource, CommunityResourceModel>(
  {
    name: { type: String, required: true },
    shortName: { type: String },
    email: { type: String },
    phone: { type: String },
    websiteUrl: { type: String },
    logo: { type: String },
  },
  {
    timestamps: true,
  }
);

export const CommunityResource = model<ICommunityResource, CommunityResourceModel>('CommunityResource', communityResourceSchema);
