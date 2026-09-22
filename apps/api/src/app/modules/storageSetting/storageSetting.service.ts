import { Types } from 'mongoose';
import crypto from 'crypto';
import config from '../../../config';
import { StorageSetting } from './storageSetting.model';
import { IStorageSetting } from './storageSetting.interface';
import { Meeting } from '../meeting/meeting.model';
import { EgressClient } from 'livekit-server-sdk';
import { debugError } from '../../../shared/debug';

const getStorageSetting = async () => {
  let setting = await StorageSetting.findOne().sort({ updatedAt: -1 });

  // If no DB setting exists yet, initialize from environment defaults
  if (!setting) {
    setting = await StorageSetting.create({
      provider: 'AWS_S3',
      bucket: config.s3.bucket || '',
      region: config.s3.region || 'us-east-1',
      accessKey: config.s3.accessKey || '',
      secretKey: config.s3.secretKey || '',
      endpoint: config.s3.endpoint || '',
      livekitUrl: config.livekit.url || '',
      livekitApiKey: config.livekit.apiKey || '',
      livekitApiSecret: config.livekit.apiSecret || '',
      autoRecordMeetings: true,
      isActive: true,
    });
  }

  // Mask sensitive secret keys for client safe response
  const settingObj = setting.toObject();
  const maskedSecretKey = settingObj.secretKey
    ? `${settingObj.secretKey.slice(0, 4)}••••••••${settingObj.secretKey.slice(-4)}`
    : '';
  const maskedLivekitSecret = settingObj.livekitApiSecret
    ? `${settingObj.livekitApiSecret.slice(0, 4)}••••••••${settingObj.livekitApiSecret.slice(-4)}`
    : '';

  return {
    ...settingObj,
    maskedSecretKey,
    maskedLivekitSecret,
  };
};

const saveStorageSetting = async (
  payload: Partial<IStorageSetting>,
  userId?: string
) => {
  let setting = await StorageSetting.findOne().sort({ updatedAt: -1 });

  const updateData: Partial<IStorageSetting> & { updatedBy?: Types.ObjectId } = {
    ...payload,
  };
  if (userId) {
    updateData.updatedBy = new Types.ObjectId(userId);
  }

  // If secretKey was masked or not provided, preserve existing
  if (
    setting &&
    (!updateData.secretKey ||
      updateData.secretKey.includes('•') ||
      updateData.secretKey.includes('*'))
  ) {
    delete updateData.secretKey;
  }

  if (
    setting &&
    (!updateData.livekitApiSecret ||
      updateData.livekitApiSecret.includes('•') ||
      updateData.livekitApiSecret.includes('*'))
  ) {
    delete updateData.livekitApiSecret;
  }

  if (setting) {
    setting = await StorageSetting.findByIdAndUpdate(setting._id, updateData, {
      new: true,
      runValidators: true,
    });
  } else {
    setting = await StorageSetting.create(updateData);
  }

  // Synchronize runtime config dynamically so restart is NOT needed
  if (setting) {
    if (setting.bucket) config.s3.bucket = setting.bucket;
    if (setting.region) config.s3.region = setting.region;
    if (setting.accessKey) config.s3.accessKey = setting.accessKey;
    if (setting.secretKey) config.s3.secretKey = setting.secretKey;
    if (setting.endpoint !== undefined) config.s3.endpoint = setting.endpoint;
    if (setting.livekitUrl) config.livekit.url = setting.livekitUrl;
    if (setting.livekitApiKey) config.livekit.apiKey = setting.livekitApiKey;
    if (setting.livekitApiSecret) config.livekit.apiSecret = setting.livekitApiSecret;
  }

  return await getStorageSetting();
};

const testAwsS3Connection = async (
  bucket: string,
  region: string,
  accessKey: string,
  secretKey: string,
  endpoint?: string
): Promise<{ success: boolean; message: string }> => {
  const host = endpoint
    ? endpoint.replace(/^https?:\/\//, '').replace(/\/.*$/, '')
    : `${bucket}.s3.${region}.amazonaws.com`;
  const url = endpoint
    ? `${endpoint.replace(/\/$/, '')}/${bucket}`
    : `https://${host}`;

  try {
    const date = new Date();
    const amzDate = date.toISOString().replace(/[:-]|\.\d{3}/g, '');
    const dateStamp = amzDate.slice(0, 8);

    const service = 's3';
    const method = 'HEAD';
    const canonicalUri = '/';
    const canonicalQueryString = '';
    const payloadHash = crypto.createHash('sha256').update('').digest('hex');

    const canonicalHeaders = `host:${host}\nx-amz-content-sha256:${payloadHash}\nx-amz-date:${amzDate}\n`;
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    const canonicalRequest = `${method}\n${canonicalUri}\n${canonicalQueryString}\n${canonicalHeaders}\n${signedHeaders}\n${payloadHash}`;

    const algorithm = 'AWS4-HMAC-SHA256';
    const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
    const stringToSign = `${algorithm}\n${amzDate}\n${credentialScope}\n${crypto.createHash('sha256').update(canonicalRequest).digest('hex')}`;

    const kDate = crypto.createHmac('sha256', `AWS4${secretKey}`).update(dateStamp).digest();
    const kRegion = crypto.createHmac('sha256', kDate).update(region).digest();
    const kService = crypto.createHmac('sha256', kRegion).update(service).digest();
    const kSigning = crypto.createHmac('sha256', kService).update('aws4_request').digest();
    const signature = crypto.createHmac('sha256', kSigning).update(stringToSign).digest('hex');

    const authorizationHeader = `${algorithm} Credential=${accessKey}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

    const res = await fetch(url, {
      method: 'HEAD',
      headers: {
        'Host': host,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
        'Authorization': authorizationHeader,
      },
    });

    if (res.status === 200 || res.status === 204) {
      return { success: true, message: `Connected to S3 bucket "${bucket}" successfully!` };
    } else if (res.status === 403) {
      return { success: false, message: `S3 Access Denied (403): Check IAM permissions for user on bucket "${bucket}".` };
    } else if (res.status === 404) {
      return { success: false, message: `S3 Bucket Not Found (404): Bucket "${bucket}" does not exist in region "${region}".` };
    } else {
      return { success: false, message: `S3 verification returned HTTP status ${res.status}.` };
    }
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    return { success: false, message: `S3 endpoint check: ${errorMsg}` };
  }
};

const testStorageConnection = async (payload: Partial<IStorageSetting>) => {
  const provider = payload.provider || 'AWS_S3';
  const bucket = payload.bucket;
  const region = payload.region || 'us-east-1';
  const accessKey = payload.accessKey;
  let secretKey = payload.secretKey;
  const endpoint = payload.endpoint;

  const setting = await StorageSetting.findOne().sort({ updatedAt: -1 });

  // Unmask secretKey if masked with bullets or asterisks
  if (!secretKey || secretKey.includes('•') || secretKey.includes('*')) {
    secretKey = setting?.secretKey || config.s3.secretKey;
  }

  const livekitUrl = payload.livekitUrl || setting?.livekitUrl || config.livekit.url;
  const livekitApiKey = payload.livekitApiKey || setting?.livekitApiKey || config.livekit.apiKey;
  let livekitApiSecret = payload.livekitApiSecret;

  if (!livekitApiSecret || livekitApiSecret.includes('•') || livekitApiSecret.includes('*')) {
    livekitApiSecret = setting?.livekitApiSecret || config.livekit.apiSecret;
  }

  if (!bucket || !accessKey) {
    return {
      success: false,
      message: 'S3 Bucket name and Access Key ID are required to test connection.',
    };
  }

  if (!secretKey) {
    return {
      success: false,
      message: 'Please provide the S3 Secret Access Key to verify storage connection.',
    };
  }

  // 1. Direct S3 Signature check
  const s3Result = await testAwsS3Connection(bucket, region, accessKey, secretKey, endpoint);
  if (!s3Result.success) {
    return s3Result;
  }

  // 2. Test LiveKit Server Egress connectivity if credentials are provided
  if (livekitUrl && livekitApiKey && livekitApiSecret) {
    try {
      const host = livekitUrl
        .replace(/^wss:\/\//, 'https://')
        .replace(/^ws:\/\//, 'http://');

      const egressClient = new EgressClient(host, livekitApiKey, livekitApiSecret);
      await egressClient.listEgress({});

      return {
        success: true,
        message: `Successfully verified S3 storage bucket "${bucket}" and connected to LiveKit WebRTC Egress!`,
        details: {
          provider,
          bucket,
          region,
          endpoint: endpoint || '(default AWS)',
          livekitHost: host,
        },
      };
    } catch (err: unknown) {
      const errMsg = err instanceof Error ? err.message : String(err);
      debugError('[StorageSetting] Connection test failed:', errMsg);
      return {
        success: false,
        message: `S3 storage verified, but LiveKit Egress check returned: ${errMsg || 'Unauthorized access'}`,
      };
    }
  }

  return {
    success: true,
    message: `Storage parameters for ${provider} format validated successfully!`,
  };
};

const getAllRecordings = async (
  query: {
    page?: number | string;
    limit?: number | string;
    searchTerm?: string;
    category?: string;
  } = {}
) => {
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 15));
  const skip = (page - 1) * limit;

  // Filter meetings that have recordingUrl or items in recordings array
  const filter: Record<string, unknown> = {
    $or: [
      { recordingUrl: { $exists: true, $ne: '' } },
      { 'recordings.0': { $exists: true } },
    ],
  };

  if (query.category && query.category !== 'ALL') {
    filter.category = query.category;
  }

  if (query.searchTerm) {
    filter.$and = [
      {
        $or: [
          { topic: { $regex: query.searchTerm, $options: 'i' } },
          { roomName: { $regex: query.searchTerm, $options: 'i' } },
          { locationAddress: { $regex: query.searchTerm, $options: 'i' } },
        ],
      },
    ];
  }

  const meetings = await Meeting.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate('userId', 'name email role image phoneNumber')
    .populate('participantId', 'name email role image phoneNumber')
    .populate('joinedAttorneys', 'name email image role');

  const total = await Meeting.countDocuments(filter);

  // Compute aggregate statistics across all recordings
  const allRecordedMeetings = await Meeting.find({
    $or: [
      { recordingUrl: { $exists: true, $ne: '' } },
      { 'recordings.0': { $exists: true } },
    ],
  }).select('recordings durationMinutes');

  let totalBytes = 0;
  let totalDurationMinutes = 0;

  allRecordedMeetings.forEach((m) => {
    totalDurationMinutes += m.durationMinutes || 0;
    if (Array.isArray(m.recordings)) {
      m.recordings.forEach((r) => {
        totalBytes += Number(r.fileSize || 0);
      });
    }
  });

  const totalSizeMB = Math.round((totalBytes / (1024 * 1024)) * 10) / 10;

  const currentSetting = await StorageSetting.findOne().sort({ updatedAt: -1 });

  return {
    meta: {
      page,
      limit,
      total,
      totalPage: Math.ceil(total / limit),
    },
    summary: {
      totalRecordings: total,
      totalDurationMinutes,
      totalSizeMB,
      provider: currentSetting?.provider || 'AWS_S3',
      bucket: currentSetting?.bucket || config.s3.bucket || 'Not configured',
      isConfigured: Boolean(currentSetting?.bucket && currentSetting?.accessKey),
    },
    data: meetings,
  };
};

const deleteRecordingFromMeeting = async (meetingId: string) => {
  const meeting = await Meeting.findByIdAndUpdate(
    meetingId,
    {
      $set: {
        recordingUrl: '',
        recordings: [],
      },
    },
    { new: true }
  );

  return meeting;
};

export const StorageSettingService = {
  getStorageSetting,
  saveStorageSetting,
  testStorageConnection,
  getAllRecordings,
  deleteRecordingFromMeeting,
};
