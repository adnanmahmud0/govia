"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HeroHighlight = void 0;
const mongoose_1 = require("mongoose");
const heroHighlightSchema = new mongoose_1.Schema({
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
    uploadedBy: { type: mongoose_1.Schema.Types.ObjectId, ref: 'User', required: true },
}, {
    timestamps: true,
});
exports.HeroHighlight = (0, mongoose_1.model)('HeroHighlight', heroHighlightSchema);
