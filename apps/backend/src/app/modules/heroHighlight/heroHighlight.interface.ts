import { Model, Types } from 'mongoose';

export type IHeroHighlight = {
  officerId?: Types.ObjectId;
  officerName: string;
  officerRank?: string;
  badgeNumber?: string;
  agency: string;
  carNumber?: string;
  officerAvatar?: string;
  respectRating: number;
  deEscalationRating: number;
  communicationRating: number;
  whatDidOfficerDoWell: string;
  incidentDate: Date;
  incidentLocation: string;
  shareWithAgency?: boolean;
  includeInMetrics?: boolean;
  shareWithCourt?: boolean;
  uploadedBy: Types.ObjectId;
  likes?: number;
  salutes?: Types.ObjectId[];
  createdAt?: Date;
  updatedAt?: Date;
};

export type HeroHighlightModel = Model<IHeroHighlight, Record<string, unknown>>;

