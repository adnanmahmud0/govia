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
exports.MeetingController = void 0;
const http_status_codes_1 = require("http-status-codes");
const catchAsync_1 = __importDefault(require("../../../shared/catchAsync"));
const sendResponse_1 = __importDefault(require("../../../shared/sendResponse"));
const meeting_service_1 = require("./meeting.service");
const startGovia = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.id;
    const result = yield meeting_service_1.MeetingService.createZoomMeeting(userId, 'Govia Consultation');
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Meeting created successfully',
        data: result,
    });
}));
const emergencyCall = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.id;
    const result = yield meeting_service_1.MeetingService.createZoomMeeting(userId, 'Emergency Protocol - I feel unsafe');
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Emergency meeting created successfully',
        data: result,
    });
}));
const getRecordings = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { meetingId } = req.params;
    const result = yield meeting_service_1.MeetingService.getMeetingRecordings(meetingId);
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Meeting recordings retrieved successfully',
        data: result,
    });
}));
const getActiveMeetings = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const result = yield meeting_service_1.MeetingService.getActiveMeetings();
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Active meetings retrieved successfully',
        data: result,
    });
}));
const joinMeeting = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    const attorneyId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.id;
    const { meetingId } = req.params;
    const result = yield meeting_service_1.MeetingService.joinMeeting(meetingId, attorneyId);
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Joined meeting successfully',
        data: result,
    });
}));
const getAttorneyRecordings = (0, catchAsync_1.default)((req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    const attorneyId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.id;
    const result = yield meeting_service_1.MeetingService.getAttorneyRecordings(attorneyId);
    (0, sendResponse_1.default)(res, {
        success: true,
        statusCode: http_status_codes_1.StatusCodes.OK,
        message: 'Attorney recordings retrieved successfully',
        data: result,
    });
}));
exports.MeetingController = {
    startGovia,
    emergencyCall,
    getRecordings,
    getActiveMeetings,
    joinMeeting,
    getAttorneyRecordings,
};
