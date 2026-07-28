"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommunityResource = void 0;
const mongoose_1 = require("mongoose");
const communityResourceSchema = new mongoose_1.Schema({
    name: { type: String, required: true },
    shortName: { type: String },
    email: { type: String },
    phone: { type: String },
    websiteUrl: { type: String },
    logo: { type: String },
}, {
    timestamps: true,
});
exports.CommunityResource = (0, mongoose_1.model)('CommunityResource', communityResourceSchema);
