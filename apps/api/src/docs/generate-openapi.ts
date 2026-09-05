import { OpenApiGeneratorV3 } from '@asteasolutions/zod-to-openapi';
import config from '../config';
import { registry } from './openapi-registry';

// Import all module OpenAPI registrations
import '../app/modules/auth/auth.openapi';
import '../app/modules/user/user.openapi';
import '../app/modules/meeting/meeting.openapi';
import '../app/modules/message/message.openapi';
import '../app/modules/conversation/conversation.openapi';
import '../app/modules/communityResource/communityResource.openapi';
import '../app/modules/aiAssistant/aiAssistant.openapi';
import '../app/modules/heroHighlight/heroHighlight.openapi';
import '../app/modules/goviaRecording/goviaRecording.openapi';

export const generateOpenApiDocument = () => {
  const generator = new OpenApiGeneratorV3(registry.definitions);

  return generator.generateDocument({
    openapi: '3.0.0',
    info: {
      title: `${config.branding?.projectName || 'Govia'} API Docs`,
      version: '1.0.0',
      description:
        'Comprehensive REST API & Real-Time Socket documentation for the Govia platform.',
    },
    servers: [
      {
        url: '/api/v1',
        description: 'API Version 1 Base Path',
      },
    ],
  });
};
