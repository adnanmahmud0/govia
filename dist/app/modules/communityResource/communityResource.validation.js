"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommunityResourceValidation = void 0;
const zod_1 = require("zod");
const createCommunityResourceZodSchema = zod_1.z.object({
    body: zod_1.z.object({
        name: zod_1.z.string({
            required_error: 'Name is required',
        }),
        shortName: zod_1.z.string().optional(),
        email: zod_1.z.string().email().optional(),
        phone: zod_1.z.string().optional(),
        websiteUrl: zod_1.z.string().url().optional(),
    }),
});
const updateCommunityResourceZodSchema = zod_1.z.object({
    body: zod_1.z.object({
        name: zod_1.z.string().optional(),
        shortName: zod_1.z.string().optional(),
        email: zod_1.z.string().email().optional(),
        phone: zod_1.z.string().optional(),
        websiteUrl: zod_1.z.string().url().optional(),
    }),
});
exports.CommunityResourceValidation = {
    createCommunityResourceZodSchema,
    updateCommunityResourceZodSchema,
};
