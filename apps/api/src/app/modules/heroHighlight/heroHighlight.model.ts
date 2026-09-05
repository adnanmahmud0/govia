import { Schema, model } from 'mongoose';
import { HeroHighlightModel, IHeroHighlight } from './heroHighlight.interface';

const heroHighlightSchema = new Schema<IHeroHighlight, HeroHighlightModel>(
  {
    officerName: { type: String, required: true },
    badgeNumber: { type: String },
    agency: { type: String, required: true },
    carNumber: { type: String, required: true },
    respectRating: { type: Number, required: true, min: 0, max: 10 },
    deEscalationRating: { type: Number, required: true, min: 0, max: 10 },
    communicationRating: { type: Number, required: true, min: 0, max: 10 },
    whatDidOfficerDoWell: { type: String, required: true },
    incidentDate: { type: Date, required: true },
    incidentLocation: { type: String, required: true },
    shareWithAgency: { type: Boolean, default: false },
    includeInMetrics: { type: Boolean, default: false },
    shareWithCourt: { type: Boolean, default: false },
    uploadedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  },
  {
    timestamps: true,
  }
);

export const HeroHighlight = model<IHeroHighlight, HeroHighlightModel>('HeroHighlight', heroHighlightSchema);
