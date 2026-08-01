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
exports.MeetingService = void 0;
const config_1 = __importDefault(require("../../../config"));
const ApiError_1 = __importDefault(require("../../../errors/ApiError"));
const http_status_codes_1 = require("http-status-codes");
const meeting_model_1 = require("./meeting.model");
const mongoose_1 = require("mongoose");
const getZoomAccessToken = () => __awaiter(void 0, void 0, void 0, function* () {
    const { accountId, clientId, clientSecret } = config_1.default.zoom;
    if (!accountId || !clientId || !clientSecret) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, 'Zoom credentials are not configured properly');
    }
    const tokenUrl = `https://zoom.us/oauth/token?grant_type=account_credentials&account_id=${accountId}`;
    const authHeader = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
    try {
        const response = yield fetch(tokenUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Basic ${authHeader}`,
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });
        if (!response.ok) {
            const errorData = yield response.text();
            console.error('Zoom token error:', errorData);
            throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, `Failed to get Zoom access token: ${errorData}`);
        }
        const data = yield response.json();
        return data.access_token;
    }
    catch (error) {
        console.error('Catch error in getZoomAccessToken:', error);
        if (error instanceof ApiError_1.default)
            throw error;
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, 'Error communicating with Zoom API');
    }
});
const createZoomMeeting = (userId, topic) => __awaiter(void 0, void 0, void 0, function* () {
    const accessToken = yield getZoomAccessToken();
    const meetingUrl = 'https://api.zoom.us/v2/users/me/meetings';
    try {
        const response = yield fetch(meetingUrl, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                topic,
                type: 1, // Instant meeting
                settings: {
                    host_video: true,
                    participant_video: true,
                    join_before_host: false,
                    mute_upon_entry: true,
                    auto_recording: 'cloud',
                }
            })
        });
        if (!response.ok) {
            const errorData = yield response.text();
            throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, `Failed to create Zoom meeting: ${errorData}`);
        }
        const data = yield response.json();
        // Save to DB
        const newMeeting = yield meeting_model_1.Meeting.create({
            userId: new mongoose_1.Types.ObjectId(userId),
            zoomMeetingId: data.id.toString(),
            topic,
            joinUrl: data.join_url,
            startUrl: data.start_url,
            password: data.password,
        });
        return {
            meetingId: newMeeting._id,
            zoom_meeting_id: data.id,
            join_url: data.join_url,
            start_url: data.start_url,
            password: data.password
        };
    }
    catch (error) {
        if (error instanceof ApiError_1.default)
            throw error;
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, 'Error creating Zoom meeting');
    }
});
const getActiveMeetings = () => __awaiter(void 0, void 0, void 0, function* () {
    const activeMeetings = yield meeting_model_1.Meeting.find({ status: 'ACTIVE' }).populate('userId', 'name email');
    return activeMeetings;
});
const joinMeeting = (meetingId, attorneyId) => __awaiter(void 0, void 0, void 0, function* () {
    const meeting = yield meeting_model_1.Meeting.findById(meetingId);
    if (!meeting) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.NOT_FOUND, 'Meeting not found');
    }
    // Avoid duplicates
    const objAttorneyId = new mongoose_1.Types.ObjectId(attorneyId);
    if (!meeting.joinedAttorneys.includes(objAttorneyId)) {
        meeting.joinedAttorneys.push(objAttorneyId);
        yield meeting.save();
    }
    return { joinUrl: meeting.joinUrl };
});
const getMeetingRecordings = (zoomMeetingId) => __awaiter(void 0, void 0, void 0, function* () {
    const accessToken = yield getZoomAccessToken();
    const url = `https://api.zoom.us/v2/meetings/${zoomMeetingId}/recordings`;
    try {
        const response = yield fetch(url, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${accessToken}`,
            }
        });
        if (!response.ok) {
            const errorData = yield response.text();
            throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, `Failed to fetch Zoom meeting recordings: ${errorData}`);
        }
        const data = yield response.json();
        return data;
    }
    catch (error) {
        if (error instanceof ApiError_1.default)
            throw error;
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, 'Error fetching Zoom meeting recordings');
    }
});
const getAttorneyRecordings = (attorneyId) => __awaiter(void 0, void 0, void 0, function* () {
    // Find all meetings this attorney joined
    const meetings = yield meeting_model_1.Meeting.find({ joinedAttorneys: new mongoose_1.Types.ObjectId(attorneyId) });
    const results = [];
    for (const m of meetings) {
        try {
            const recordings = yield getMeetingRecordings(m.zoomMeetingId);
            results.push({
                meeting: m,
                recordings
            });
        }
        catch (e) {
            // Continue even if one fails
            results.push({ meeting: m, recordings: null, error: 'Failed to fetch recordings' });
        }
    }
    return results;
});
exports.MeetingService = {
    createZoomMeeting,
    getMeetingRecordings,
    getActiveMeetings,
    joinMeeting,
    getAttorneyRecordings,
};
