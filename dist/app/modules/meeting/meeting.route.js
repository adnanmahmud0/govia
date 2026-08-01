"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MeetingRoutes = void 0;
const express_1 = __importDefault(require("express"));
const meeting_controller_1 = require("./meeting.controller");
const auth_1 = __importDefault(require("../../middlewares/auth"));
const user_1 = require("../../../enums/user");
const router = express_1.default.Router();
router.post('/start-govia', (0, auth_1.default)(user_1.USER_ROLES.USER, user_1.USER_ROLES.CITIZEN), meeting_controller_1.MeetingController.startGovia);
router.post('/emergency-call', (0, auth_1.default)(user_1.USER_ROLES.USER, user_1.USER_ROLES.CITIZEN), meeting_controller_1.MeetingController.emergencyCall);
// Get recordings (admin or specific user check might be needed, currently just protecting it)
router.get('/:meetingId/recordings', (0, auth_1.default)(user_1.USER_ROLES.USER, user_1.USER_ROLES.CITIZEN, user_1.USER_ROLES.ATTORNEY), meeting_controller_1.MeetingController.getRecordings);
// Get list of active meetings (Attorney view)
router.get('/active', (0, auth_1.default)(user_1.USER_ROLES.ATTORNEY, user_1.USER_ROLES.ADMIN), meeting_controller_1.MeetingController.getActiveMeetings);
// Join a meeting (Attorney action)
router.post('/:meetingId/join', (0, auth_1.default)(user_1.USER_ROLES.ATTORNEY), meeting_controller_1.MeetingController.joinMeeting);
// Get recordings for meetings the attorney has joined
router.get('/attorney-recordings', (0, auth_1.default)(user_1.USER_ROLES.ATTORNEY), meeting_controller_1.MeetingController.getAttorneyRecordings);
exports.MeetingRoutes = router;
