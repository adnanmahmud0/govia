import { Schema, model } from 'mongoose';
import { HeroHighlightModel, IHeroHighlight } from './heroHighlight.interface';

const heroHighlightSchema = new Schema<IHeroHighlight, HeroHighlightModel>(
  {
    officerId: { type: Schema.Types.ObjectId, ref: 'User' },
    officerName: { type: String, required: true },
    officerRank: { type: String, default: 'Officer' },
    badgeNumber: { type: String },
    agency: { type: String, required: true },
    carNumber: { type: String, default: '' },
    officerAvatar: { type: String },
    overallRating: { type: Number, min: 1, max: 5, default: 5 },
    respectRating: { type: Number, min: 0, max: 10, default: 5 },
    deEscalationRating: { type: Number, min: 0, max: 10, default: 5 },
    communicationRating: { type: Number, min: 0, max: 10, default: 5 },
    whatDidOfficerDoWell: { type: String, required: true },
    incidentDate: { type: Date, default: Date.now },
    incidentLocation: { type: String, default: 'Current Location' },
    shareWithAgency: { type: Boolean, default: true },
    includeInMetrics: { type: Boolean, default: true },
    shareWithCourt: { type: Boolean, default: true },
    uploadedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    likes: { type: Number, default: 0 },
    salutes: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  },
  {
    timestamps: true,
  }
);

export const HeroHighlight = model<IHeroHighlight, HeroHighlightModel>('HeroHighlight', heroHighlightSchema);
