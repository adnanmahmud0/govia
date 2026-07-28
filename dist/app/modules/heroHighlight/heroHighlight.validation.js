"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.HeroHighlightValidation = void 0;
const zod_1 = require("zod");
const createHeroHighlightZodSchema = zod_1.z.object({
    body: zod_1.z.object({
        officerName: zod_1.z.string({
            required_error: 'Officer Name is required',
        }),
        badgeNumber: zod_1.z.string().optional(),
        agency: zod_1.z.string({
            required_error: 'Agency is required',
        }),
        carNumber: zod_1.z.string({
            required_error: 'Car Number is required',
        }),
        respectRating: zod_1.z
            .number({
            required_error: 'Respect Rating is required',
        })
            .min(0, 'Rating must be at least 0')
            .max(10, 'Rating must be at most 10'),
        deEscalationRating: zod_1.z
            .number({
            required_error: 'De-escalation Rating is required',
        })
            .min(0, 'Rating must be at least 0')
            .max(10, 'Rating must be at most 10'),
        communicationRating: zod_1.z
            .number({
            required_error: 'Communication Rating is required',
        })
            .min(0, 'Rating must be at least 0')
            .max(10, 'Rating must be at most 10'),
        whatDidOfficerDoWell: zod_1.z.string({
            required_error: 'Feedback is required',
        }),
        incidentDate: zod_1.z.string({
            required_error: 'Incident Date is required',
        }),
        incidentLocation: zod_1.z.string({
            required_error: 'Incident Location is required',
        }),
        shareWithAgency: zod_1.z.boolean().optional(),
        includeInMetrics: zod_1.z.boolean().optional(),
        shareWithCourt: zod_1.z.boolean().optional(),
    }),
});
exports.HeroHighlightValidation = {
    createHeroHighlightZodSchema,
};
