"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const auth_route_1 = require("../app/modules/auth/auth.route");
const user_route_1 = require("../app/modules/user/user.route");
const meeting_route_1 = require("../app/modules/meeting/meeting.route");
const heroHighlight_route_1 = require("../app/modules/heroHighlight/heroHighlight.route");
const aiAssistant_route_1 = require("../app/modules/aiAssistant/aiAssistant.route");
const communityResource_route_1 = require("../app/modules/communityResource/communityResource.route");
const goviaRecording_route_1 = require("../app/modules/goviaRecording/goviaRecording.route");
const router = express_1.default.Router();
const apiRoutes = [
    {
        path: '/user',
        route: user_route_1.UserRoutes,
    },
    {
        path: '/auth',
        route: auth_route_1.AuthRoutes,
    },
    {
        path: '/meeting',
        route: meeting_route_1.MeetingRoutes,
    },
    {
        path: '/heroHighlight',
        route: heroHighlight_route_1.HeroHighlightRoutes,
    },
    {
        path: '/aiAssistant',
        route: aiAssistant_route_1.AiAssistantRoutes,
    },
    {
        path: '/communityResource',
        route: communityResource_route_1.CommunityResourceRoutes,
    },
    {
        path: '/goviaRecording',
        route: goviaRecording_route_1.GoviaRecordingRoutes,
    },
];
apiRoutes.forEach(route => router.use(route.path, route.route));
exports.default = router;
