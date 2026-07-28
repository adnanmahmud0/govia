"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MeetingRoutes = void 0;
const express_1 = __importDefault(require("express"));
const auth_1 = __importDefault(require("../../middlewares/auth"));
const user_1 = require("../../../enums/user");
const meeting_controller_1 = require("./meeting.controller");
const router = express_1.default.Router();
router.post('/start-govia', (0, auth_1.default)(user_1.USER_ROLES.CITIZEN, user_1.USER_ROLES.USER, user_1.USER_ROLES.SUPER_ADMIN, user_1.USER_ROLES.ADMIN), meeting_controller_1.MeetingController.startGovia);
router.post('/emergency-call', (0, auth_1.default)(user_1.USER_ROLES.CITIZEN, user_1.USER_ROLES.USER, user_1.USER_ROLES.SUPER_ADMIN, user_1.USER_ROLES.ADMIN), meeting_controller_1.MeetingController.emergencyCall);
exports.MeetingRoutes = router;
