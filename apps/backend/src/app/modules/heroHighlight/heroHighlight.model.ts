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
    respectRating: { type: Number, required: true, min: 0, max: 10 },
    deEscalationRating: { type: Number, required: true, min: 0, max: 10 },
    communicationRating: { type: Number, required: true, min: 0, max: 10 },
    whatDidOfficerDoWell: { type: String, required: true },
    incidentDate: { type: Date, required: true },
    incidentLocation: { type: String, required: true },
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
