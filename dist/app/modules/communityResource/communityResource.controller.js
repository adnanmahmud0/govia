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
exports.CommunityResourceController = void 0;
const http_status_codes_1 = require("http-status-codes");
const catchAsync_1 = __importDefault(require("../../../shared/catchAsync"));
const sendResponse_1 = __importDefault(require("../../../shared/sendResponse"));
const getFilePath_1 = require("../../../shared/getFilePath");
const communityResource_service_1 = require("./communityResource.service");
const createResource = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const logo = (0, getFilePath_1.getSingleFilePath)(req.files, 'image');
    const payload = Object.assign(Object.assign({}, req.body), { logo });
    const result = yield communityResource_service_1.CommunityResourceService.createResourceToDB(payload);
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.CREATED,
        message: 'Community Resource created successfully',
        data: result,
    });
}));
const getAllResources = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const result = yield communityResource_service_1.CommunityResourceService.getAllResourcesFromDB();
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Community Resources retrieved successfully',
        data: result,
    });
}));
const getSingleResource = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { id } = req.params;
    const result = yield communityResource_service_1.CommunityResourceService.getSingleResourceFromDB(id);
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Community Resource retrieved successfully',
        data: result,
    });
}));
const updateResource = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { id } = req.params;
    const logo = (0, getFilePath_1.getSingleFilePath)(req.files, 'image');
    const payload = Object.assign({}, req.body);
    if (logo) {
        payload.logo = logo;
    }
    const result = yield communityResource_service_1.CommunityResourceService.updateResourceInDB(id, payload);
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Community Resource updated successfully',
        data: result,
    });
}));
const deleteResource = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { id } = req.params;
    const result = yield communityResource_service_1.CommunityResourceService.deleteResourceFromDB(id);
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Community Resource deleted successfully',
        data: result,
    });
}));
exports.CommunityResourceController = {
    createResource,
    getAllResources,
    getSingleResource,
    updateResource,
    deleteResource,
};
