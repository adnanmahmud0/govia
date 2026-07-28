"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommunityResourceService = void 0;
const communityResource_model_1 = require("./communityResource.model");
const ApiError_1 = __importDefault(require("../../../errors/ApiError"));
const http_status_codes_1 = require("http-status-codes");
const createResourceToDB = (payload) => __awaiter(void 0, void 0, void 0, function* () {
    const result = yield communityResource_model_1.CommunityResource.create(payload);
    return result;
});
const getAllResourcesFromDB = () => __awaiter(void 0, void 0, void 0, function* () {
    const result = yield communityResource_model_1.CommunityResource.find();
    return result;
});
const getSingleResourceFromDB = (id) => __awaiter(void 0, void 0, void 0, function* () {
    const result = yield communityResource_model_1.CommunityResource.findById(id);
    if (!result) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.NOT_FOUND, 'Community Resource not found');
    }
    return result;
});
const updateResourceInDB = (id, payload) => __awaiter(void 0, void 0, void 0, function* () {
    const result = yield communityResource_model_1.CommunityResource.findByIdAndUpdate(id, payload, { new: true });
    if (!result) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.NOT_FOUND, 'Community Resource not found');
    }
    return result;
});
const deleteResourceFromDB = (id) => __awaiter(void 0, void 0, void 0, function* () {
    const result = yield communityResource_model_1.CommunityResource.findByIdAndDelete(id);
    if (!result) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.NOT_FOUND, 'Community Resource not found');
    }
    return result;
});
exports.CommunityResourceService = {
    createResourceToDB,
    getAllResourcesFromDB,
    getSingleResourceFromDB,
    updateResourceInDB,
    deleteResourceFromDB,
};
