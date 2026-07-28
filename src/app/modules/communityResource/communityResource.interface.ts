import { Model } from 'mongoose';

export type ICommunityResource = {
  name: string;
  shortName?: string;
  email?: string;
  phone?: string;
  websiteUrl?: string;
  logo?: string;
};

export type CommunityResourceModel = Model<ICommunityResource, Record<string, unknown>>;
