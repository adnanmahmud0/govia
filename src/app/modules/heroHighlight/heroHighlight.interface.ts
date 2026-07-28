import { Model, Types } from 'mongoose';

export type IHeroHighlight = {
  officerName: string;
  badgeNumber?: string;
  agency: string;
  carNumber: string;
  respectRating: number;
  deEscalationRating: number;
  communicationRating: number;
  whatDidOfficerDoWell: string;
  incidentDate: Date;
  incidentLocation: string;
  shareWithAgency: boolean;
  includeInMetrics: boolean;
  shareWithCourt: boolean;
  uploadedBy: Types.ObjectId;
};

export type HeroHighlightModel = Model<IHeroHighlight, Record<string, unknown>>;
