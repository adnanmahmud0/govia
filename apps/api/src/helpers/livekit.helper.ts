import { AccessToken } from 'livekit-server-sdk';
import config from '../config';

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

export default {
  createLiveKitToken,
};
