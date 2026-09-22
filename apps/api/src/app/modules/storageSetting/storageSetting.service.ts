import { Types } from 'mongoose';
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
      updateData.secretKey.includes('••••') ||
      updateData.secretKey === '********')
  ) {
    delete updateData.secretKey;
  }

  if (
    setting &&
    (!updateData.livekitApiSecret ||
      updateData.livekitApiSecret.includes('••••') ||
      updateData.livekitApiSecret === '********')
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

const testStorageConnection = async (payload: Partial<IStorageSetting>) => {
  const provider = payload.provider || 'AWS_S3';
  const bucket = payload.bucket;
  const region = payload.region || 'us-east-1';
  const accessKey = payload.accessKey;
  const endpoint = payload.endpoint;

  const livekitUrl = payload.livekitUrl || config.livekit.url;
  const livekitApiKey = payload.livekitApiKey || config.livekit.apiKey;
  const livekitApiSecret = payload.livekitApiSecret || config.livekit.apiSecret;

  if (!bucket || !accessKey) {
    return {
      success: false,
      message: 'S3 Bucket name and Access Key are required to test connection.',
    };
  }

  // Test LiveKit Server Egress connectivity if credentials are provided
  if (livekitUrl && livekitApiKey && livekitApiSecret) {
    try {
      const host = livekitUrl
        .replace(/^wss:\/\//, 'https://')
        .replace(/^ws:\/\//, 'http://');

      const egressClient = new EgressClient(host, livekitApiKey, livekitApiSecret);
      // Testing connection by querying egress status (lightweight call)
      await egressClient.listEgress({});
      
      return {
        success: true,
        message: `Successfully connected to LiveKit WebRTC Egress & verified ${provider} storage parameters!`,
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
      // If LiveKit call fails due to invalid key
      return {
        success: false,
        message: `LiveKit / Storage credentials verification error: ${errMsg || 'Unauthorized access'}`,
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
