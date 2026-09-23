import {
  AccessToken,
  EgressClient,
  EncodedFileOutput,
  RoomServiceClient,
  S3Upload,
  WebhookReceiver,
} from 'livekit-server-sdk';
import config from '../config';
import { debug, debugError } from '../shared/debug';
import { StorageSetting } from '../app/modules/storageSetting/storageSetting.model';

export type TokenOptions = {
  roomName: string;
  participantIdentity: string;
  participantName?: string;
  metadata?: Record<string, unknown>;
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
  let apiKey = config.livekit.apiKey;
  let apiSecret = config.livekit.apiSecret;

  try {
    const dbSetting = await StorageSetting.findOne().sort({ updatedAt: -1 });
    if (dbSetting?.livekitApiKey && dbSetting?.livekitApiSecret) {
      apiKey = dbSetting.livekitApiKey;
      apiSecret = dbSetting.livekitApiSecret;
    }
  } catch (_err) {
    // fallback to config
  }

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
): Promise<Record<string, unknown> | null> => {
  let apiKey = config.livekit.apiKey;
  let apiSecret = config.livekit.apiSecret;
  let livekitUrl = config.livekit.url;

  let s3Bucket = config.s3.bucket;
  let s3Region = config.s3.region || 'us-east-1';
  let s3AccessKey = config.s3.accessKey;
  let s3SecretKey = config.s3.secretKey;
  let s3Endpoint = config.s3.endpoint || '';

  try {
    const dbSetting = await StorageSetting.findOne().sort({ updatedAt: -1 });
    if (dbSetting) {
      if (dbSetting.bucket) s3Bucket = dbSetting.bucket;
      if (dbSetting.region) s3Region = dbSetting.region;
      if (dbSetting.accessKey) s3AccessKey = dbSetting.accessKey;
      if (dbSetting.secretKey) s3SecretKey = dbSetting.secretKey;
      if (dbSetting.endpoint !== undefined) s3Endpoint = dbSetting.endpoint;
      if (dbSetting.livekitApiKey) apiKey = dbSetting.livekitApiKey;
      if (dbSetting.livekitApiSecret) apiSecret = dbSetting.livekitApiSecret;
      if (dbSetting.livekitUrl) livekitUrl = dbSetting.livekitUrl;
    }
  } catch (_err) {
    // fallback to config
  }

  const host = livekitUrl
    .replace(/^wss:\/\//, 'https://')
    .replace(/^ws:\/\//, 'http://');

  if (!apiKey || !apiSecret || !host) {
    debug('[LiveKit] Missing API key or secret for Egress');
    return null;
  }

  // S3 storage must be configured for cloud egress uploads
  if (!s3Bucket || !s3AccessKey || !s3SecretKey) {
    debug(
      '[LiveKit] S3 bucket or credentials not set in DB or .env. Skipping cloud egress.'
    );
    return null;
  }

  try {
    // 1. Ensure the room exists on LiveKit Cloud before starting egress
    // (LiveKit returns 'requested room does not exist' if egress is started before any peer connects)
    try {
      const roomService = new RoomServiceClient(host, apiKey, apiSecret);
      await roomService.createRoom({ name: roomName, emptyTimeout: 300 });
      debug(`[LiveKit] Verified/created room ${roomName} prior to starting Egress`);
    } catch (roomErr) {
      debug(
        `[LiveKit] Room check notice: ${roomErr instanceof Error ? roomErr.message : String(roomErr)}`
      );
    }

    const egressClient = new EgressClient(host, apiKey, apiSecret);
    const s3Upload = new S3Upload({
      bucket: s3Bucket,
      region: s3Region || 'us-east-1',
      accessKey: s3AccessKey,
      secret: s3SecretKey,
      endpoint: s3Endpoint || '',
      forcePathStyle: !s3Region || (s3Endpoint?.length ?? 0) > 0,
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
    return info as unknown as Record<string, unknown>;
  } catch (error: unknown) {
    debugError(
      `[LiveKit] Failed to start Egress for room ${roomName}:`,
      error instanceof Error ? error.message : String(error)
    );
    return null;
  }
};

/**
 * Stops an ongoing LiveKit Egress recording.
 */
export const stopLiveKitRecording = async (
  egressId: string
): Promise<Record<string, unknown> | null> => {
  if (!egressId) return null;
  let apiKey = config.livekit.apiKey;
  let apiSecret = config.livekit.apiSecret;
  let livekitUrl = config.livekit.url;

  try {
    const dbSetting = await StorageSetting.findOne().sort({ updatedAt: -1 });
    if (dbSetting?.livekitApiKey && dbSetting?.livekitApiSecret) {
      apiKey = dbSetting.livekitApiKey;
      apiSecret = dbSetting.livekitApiSecret;
      if (dbSetting.livekitUrl) livekitUrl = dbSetting.livekitUrl;
    }
  } catch (_err) {
    // fallback
  }

  const host = livekitUrl
    .replace(/^wss:\/\//, 'https://')
    .replace(/^ws:\/\//, 'http://');

  try {
    const egressClient = new EgressClient(host, apiKey, apiSecret);
    const info = await egressClient.stopEgress(egressId);
    debug(`[LiveKit] Stopped Egress ${egressId}:`, info?.status);
    return info as unknown as Record<string, unknown>;
  } catch (error: unknown) {
    debugError(
      `[LiveKit] Failed to stop Egress ${egressId}:`,
      error instanceof Error ? error.message : String(error)
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

