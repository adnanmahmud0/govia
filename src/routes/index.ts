import express from 'express';
import { AuthRoutes } from '../app/modules/auth/auth.route';
import { UserRoutes } from '../app/modules/user/user.route';
import { MeetingRoutes } from '../app/modules/meeting/meeting.route';
import { HeroHighlightRoutes } from '../app/modules/heroHighlight/heroHighlight.route';
import { AiAssistantRoutes } from '../app/modules/aiAssistant/aiAssistant.route';
import { CommunityResourceRoutes } from '../app/modules/communityResource/communityResource.route';
import { GoviaRecordingRoutes } from '../app/modules/goviaRecording/goviaRecording.route';
const router = express.Router();

const apiRoutes = [
  {
    path: '/user',
    route: UserRoutes,
  },
  {
    path: '/auth',
    route: AuthRoutes,
  },
  {
    path: '/meeting',
    route: MeetingRoutes,
  },
  {
    path: '/heroHighlight',
    route: HeroHighlightRoutes,
  },
  {
    path: '/aiAssistant',
    route: AiAssistantRoutes,
  },
  {
    path: '/communityResource',
    route: CommunityResourceRoutes,
  },
  {
    path: '/goviaRecording',
    route: GoviaRecordingRoutes,
  },
];

apiRoutes.forEach(route => router.use(route.path, route.route));

export default router;
