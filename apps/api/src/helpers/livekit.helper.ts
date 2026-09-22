import {
  AccessToken,
  EgressClient,
  EncodedFileOutput,
  S3Upload,
  WebhookReceiver,
} from 'livekit-server-sdk';
import config from '../config';
import { debug, debugError } from '../shared/debug';

export interface TokenOptions {
  roomName: string;
  participantIdentity: string;
  participantName?: string;
  metadata?: Record<string, any>;
  canPublish?: boolean;
  canSubscribe?: boolean;
}

/**
 * Generates an encrypted JWT access token for joining a LiveKit WebRTC room.
 */
export const createLiveKitToken = async ({
  roomName,
  participantIdentity,
  participantName,
  metadata,
  canPublish = true,
  canSubscribe = true,
}: TokenOptions): Promise<string> => {
  const apiKey = config.livekit.apiKey;
  const apiSecret = config.livekit.apiSecret;

  const at = new AccessToken(apiKey, apiSecret, {
    identity: participantIdentity,
    name: participantName || participantIdentity,
    metadata: metadata ? JSON.stringify(metadata) : undefined,
    ttl: '6h', // valid for 6 hours
  });

  at.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish,
    canSubscribe,
    canPublishData: true,
  });

  return await at.toJwt();
};

/**
 * Starts a server-side composite recording via LiveKit Egress.
 * Compiles all participant audio/video into a single MP4 and uploads to S3/R2 storage.
 */
export const startLiveKitRecording = async (
  roomName: string,
  options?: { layout?: string }
): Promise<any> => {
  const apiKey = config.livekit.apiKey;
  const apiSecret = config.livekit.apiSecret;
  const host = config.livekit.url
    .replace(/^wss:\/\//, 'https://')
    .replace(/^ws:\/\//, 'http://');

  if (!apiKey || !apiSecret || !host) {
    debug('[LiveKit] Missing API key or secret for Egress');
    return null;
  }

  // S3 storage must be configured for cloud egress uploads
  if (!config.s3.bucket || !config.s3.accessKey || !config.s3.secretKey) {
    debug(
      '[LiveKit] S3 bucket or credentials not set in .env. Skipping cloud egress.'
    );
    return null;
  }

  try {
    const egressClient = new EgressClient(host, apiKey, apiSecret);
    const s3Upload = new S3Upload({
      bucket: config.s3.bucket,
      region: config.s3.region || 'us-east-1',
      accessKey: config.s3.accessKey,
      secret: config.s3.secretKey,
      endpoint: config.s3.endpoint || '',
      forcePathStyle:
        !config.s3.region || (config.s3.endpoint?.length ?? 0) > 0,
    });

    const fileOutput = new EncodedFileOutput({
      filepath: `recordings/${roomName}/{time}.mp4`,
      output: {
        case: 's3',
        value: s3Upload,
      },
    });

    const info = await egressClient.startRoomCompositeEgress(
      roomName,
      fileOutput,
      {
        layout: options?.layout || 'grid',
      }
    );

    debug(
      `[LiveKit] Egress recording started for room ${roomName}. EgressId: ${info.egressId}`
    );
    return info;
  } catch (error: any) {
    debugError(
      `[LiveKit] Failed to start Egress for room ${roomName}:`,
      error?.message || error
    );
    return null;
  }
};

/**
 * Stops an ongoing LiveKit Egress recording.
 */
export const stopLiveKitRecording = async (egressId: string): Promise<any> => {
  if (!egressId) return null;
  const apiKey = config.livekit.apiKey;
  const apiSecret = config.livekit.apiSecret;
  const host = config.livekit.url
    .replace(/^wss:\/\//, 'https://')
    .replace(/^ws:\/\//, 'http://');

  try {
    const egressClient = new EgressClient(host, apiKey, apiSecret);
    const info = await egressClient.stopEgress(egressId);
    debug(`[LiveKit] Stopped Egress ${egressId}:`, info?.status);
    return info;
  } catch (error: any) {
    debugError(
      `[LiveKit] Failed to stop Egress ${egressId}:`,
      error?.message || error
    );
    return null;
  }
};

/**
 * Verifies and parses a LiveKit Cloud Webhook payload.
 */
export const verifyLiveKitWebhook = async (
  rawBody: string,
  authHeader?: string
) => {
  const apiKey = config.livekit.apiKey;
  const apiSecret = config.livekit.apiSecret;
  const receiver = new WebhookReceiver(apiKey, apiSecret);
  const skipAuth = !authHeader;
  return await receiver.receive(rawBody, authHeader, skipAuth);
};

export default {
  createLiveKitToken,
  startLiveKitRecording,
  stopLiveKitRecording,
  verifyLiveKitWebhook,
};

