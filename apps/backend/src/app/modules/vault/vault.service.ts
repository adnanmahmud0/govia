import { StatusCodes } from 'http-status-codes';
import { HydratedDocument, Types } from 'mongoose';
import ApiError from '../../../errors/ApiError';
import { Meeting } from '../meeting/meeting.model';
import { IMeeting } from '../meeting/meeting.interface';
import { IVaultFolder, VaultCategory } from './vaultFolder.interface';
import { VaultFolder } from './vaultFolder.model';
import { IVaultItem, VaultItemType } from './vaultItem.interface';
import { VaultItem } from './vaultItem.model';

const createFolder = async (
  userId: string,
  payload: Partial<IVaultFolder>
): Promise<IVaultFolder> => {
  if (!payload.name) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Folder name is required');
  }

  const folder = await VaultFolder.create({
    ...payload,
    userId: new Types.ObjectId(userId),
    incidentDate: payload.incidentDate ? new Date(payload.incidentDate) : new Date(),
  });

  return folder;
};

const getUserFolders = async (
  userId: string,
  query: { category?: string; search?: string }
) => {
  const filter: Record<string, unknown> = {
    userId: new Types.ObjectId(userId),
    isArchived: false,
  };

  if (query.category && query.category !== 'All') {
    filter.category = query.category.toUpperCase();
  }

  if (query.search) {
    filter.$or = [
      { name: { $regex: query.search, $options: 'i' } },
      { description: { $regex: query.search, $options: 'i' } },
      { location: { $regex: query.search, $options: 'i' } },
    ];
  }

  const folders = await VaultFolder.find(filter).sort({ createdAt: -1 }).lean();

  // Aggregate items count for each folder
  const folderIds = folders.map(f => f._id);
  const items = await VaultItem.find({ folderId: { $in: folderIds } }).lean();

  const enrichedFolders = folders.map(folder => {
    const folderItems = items.filter(
      item => item.folderId.toString() === folder._id.toString()
    );

    const videoCount = folderItems.filter(i => i.fileType === 'VIDEO' || i.fileType === 'RECORDING').length;
    const audioCount = folderItems.filter(i => i.fileType === 'AUDIO').length;
    const imageCount = folderItems.filter(i => i.fileType === 'IMAGE').length;
    const docCount = folderItems.filter(i => i.fileType === 'DOCUMENT').length;

    const containedCategories = Array.from(new Set(folderItems.map(i => i.category)));
    const linkedMeetingIds = folderItems
      .map(i => i.meetingId?.toString())
      .filter((id): id is string => Boolean(id));

    return {
      ...folder,
      itemCount: folderItems.length,
      linkedMeetingIds,
      counts: {
        video: videoCount,
        audio: audioCount,
        image: imageCount,
        doc: docCount,
      },
      containedCategories,
      itemSummary: {
        total: folderItems.length,
        videos: videoCount,
        audio: audioCount,
        images: imageCount,
        docs: docCount,
      },
    };
  });

  return enrichedFolders;
};

const getFolderDetails = async (userId: string, folderId: string) => {
  const userObjectId = new Types.ObjectId(userId);
  const folder = await VaultFolder.findOne({
    _id: new Types.ObjectId(folderId),
    $or: [
      { userId: userObjectId },
      { 'sharedWith.userId': userObjectId },
    ],
  })
    .populate('userId', 'name role profilePicture image')
    .populate('sharedWith.userId', 'name role profilePicture image shortHexId')
    .lean();

  if (!folder) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Vault folder not found');
  }

  const isOwner =
    folder.userId?._id?.toString() === userId || folder.userId?.toString() === userId;
  const isReadOnly = !isOwner;

  const items = await VaultItem.find({
    folderId: new Types.ObjectId(folderId),
  })
    .populate('meetingId', 'topic category meetingType startTime durationMinutes recordingUrl zoomMeetingId')
    .sort({ createdAt: -1 })
    .lean();

  const normalizedItems = items.map(
    (
      item: Record<string, unknown> & {
        fileUrl?: string;
        meetingId?: { recordingUrl?: string; _id?: unknown };
      }
    ) => {
    if (!item.fileUrl || item.fileUrl === '') {
      if (item.meetingId?.recordingUrl) {
        item.fileUrl = item.meetingId.recordingUrl;
      } else if (item.meetingId?._id) {
        item.fileUrl = `https://recordings.govia.ai/play/${item.meetingId._id}`;
      }
    }
    return item;
  });

  return {
    folder: {
      ...folder,
      isReadOnly,
      sharedBy: isOwner ? null : folder.userId,
    },
    items: normalizedItems,
    isReadOnly,
  };
};

const updateFolder = async (
  userId: string,
  folderId: string,
  payload: Partial<IVaultFolder>
) => {
  const folder = await VaultFolder.findOneAndUpdate(
    { _id: new Types.ObjectId(folderId), userId: new Types.ObjectId(userId) },
    payload,
    { new: true }
  );

  if (!folder) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Vault folder not found');
  }

  return folder;
};

const deleteFolder = async (userId: string, folderId: string) => {
  const folder = await VaultFolder.findOneAndDelete({
    _id: new Types.ObjectId(folderId),
    userId: new Types.ObjectId(userId),
  });

  if (!folder) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Vault folder not found');
  }

  // Delete all items inside this folder
  await VaultItem.deleteMany({ folderId: new Types.ObjectId(folderId) });

  return folder;
};

const uploadEvidence = async (
  userId: string,
  folderId: string,
  uploadedFiles: Record<string, Express.Multer.File[]> | undefined,
  payload: {
    title?: string;
    description?: string;
    subCategory?: string;
    importance?: 'CRITICAL' | 'HIGH' | 'SUPPORTING' | 'GENERAL';
    fileType?: VaultItemType;
    duration?: string;
  }
) => {
  const folder = await VaultFolder.findOne({
    _id: new Types.ObjectId(folderId),
    userId: new Types.ObjectId(userId),
  });

  if (!folder) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Target vault folder not found');
  }

  const itemsToCreate: Partial<IVaultItem>[] = [];

  // Extract all files from multer fields
  const fileList: Express.Multer.File[] = [];
  if (uploadedFiles) {
    Object.keys(uploadedFiles).forEach(key => {
      const arr = uploadedFiles[key];
      if (Array.isArray(arr)) {
        fileList.push(...arr);
      }
    });
  }

  if (fileList.length === 0) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'No files were uploaded');
  }

  for (const file of fileList) {
    let fileType: VaultItemType = payload.fileType || 'DOCUMENT';
    if (!payload.fileType) {
      if (file.mimetype.startsWith('image/')) {
        fileType = 'IMAGE';
      } else if (file.mimetype.startsWith('video/')) {
        fileType = 'VIDEO';
      } else if (file.mimetype.startsWith('audio/')) {
        fileType = 'AUDIO';
      }
    }

    const relativePath = `/uploads/${file.fieldname === 'image' ? 'image' : file.fieldname === 'media' ? 'media' : 'doc'}/${file.filename}`;

    itemsToCreate.push({
      userId: new Types.ObjectId(userId),
      folderId: new Types.ObjectId(folderId),
      title: payload.title || file.originalname || 'Uploaded Evidence',
      description: payload.description || '',
      category: 'UPLOADED',
      subCategory: payload.subCategory || '',
      importance: payload.importance || 'GENERAL',
      fileType,
      fileUrl: relativePath,
      fileSize: file.size,
      mimeType: file.mimetype,
      duration: payload.duration || '',
    });
  }

  const createdItems = await VaultItem.insertMany(itemsToCreate);
  return createdItems;
};

const linkMeetingToFolder = async (
  userId: string,
  payload: {
    folderId: string;
    meetingId: string;
    title?: string;
    description?: string;
  }
) => {
  const userObjectId = new Types.ObjectId(userId);
  const folder = await VaultFolder.findOne({
    _id: new Types.ObjectId(payload.folderId),
    userId: userObjectId,
  });

  if (!folder) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Target vault folder not found');
  }

  // 1. Resolve meeting: payload.meetingId might be a direct Meeting ID OR a VaultItem ID that links to a meeting!
  let meeting: HydratedDocument<IMeeting> | null = null;
  if (Types.ObjectId.isValid(payload.meetingId)) {
    meeting = await Meeting.findById(payload.meetingId);
    if (!meeting) {
      const existingItem = await VaultItem.findById(payload.meetingId);
      if (existingItem && existingItem.meetingId) {
        meeting = await Meeting.findById(existingItem.meetingId);
      }
    }
  }

  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting record not found');
  }

  // 2. Prevent duplicate entries in the same folder
  const existingItem = await VaultItem.findOne({
    folderId: folder._id,
    meetingId: meeting._id,
  });

  if (existingItem) {
    if (payload.title) existingItem.title = payload.title.trim();
    if (payload.description) existingItem.description = payload.description.trim();
    await existingItem.save();
    return existingItem;
  }

  // 3. Category handling: Strictly map to ENCOUNTER, EMERGENCY, or CONSULTATION
  let meetingCategory: VaultCategory = 'CONSULTATION';
  if (meeting.category && ['ENCOUNTER', 'EMERGENCY', 'CONSULTATION'].includes(meeting.category)) {
    meetingCategory = meeting.category as VaultCategory;
  } else if (meeting.meetingType === 'EMERGENCY' || (meeting.topic && meeting.topic.toLowerCase().includes('emergency'))) {
    meetingCategory = 'EMERGENCY';
  } else if (meeting.topic && (meeting.topic.toLowerCase().includes('police') || meeting.topic.toLowerCase().includes('encounter') || meeting.topic.toLowerCase().includes('govia'))) {
    meetingCategory = 'ENCOUNTER';
  }

  const recordingUrl = meeting.recordingUrl || meeting.joinUrl || `https://recordings.govia.ai/play/${meeting._id}`;
  const duration = meeting.durationMinutes
    ? `${meeting.durationMinutes} mins`
    : '30 mins';

  const item = await VaultItem.create({
    userId: userObjectId,
    folderId: folder._id,
    title: payload.title?.trim() || meeting.topic || `${meetingCategory} Session Recording`,
    description: payload.description?.trim() || meeting.agenda || `Recorded ${meetingCategory.toLowerCase()} session linked to Vault.`,
    category: meetingCategory,
    fileType: 'VIDEO',
    fileUrl: recordingUrl,
    duration,
    meetingId: meeting._id,
  });

  // Link back on Meeting document
  meeting.vaultFolderId = folder._id;
  await meeting.save();

  return item;
};

const deleteItem = async (userId: string, itemId: string) => {
  const item = await VaultItem.findOneAndDelete({
    _id: new Types.ObjectId(itemId),
    userId: new Types.ObjectId(userId),
  });

  if (!item) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Evidence item not found');
  }

  return item;
};

const shareFolder = async (
  ownerId: string,
  folderId: string,
  targetUserId: string
) => {
  if (ownerId === targetUserId) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      'You cannot share a folder with yourself'
    );
  }

  const ownerObjectId = new Types.ObjectId(ownerId);
  const targetObjectId = new Types.ObjectId(targetUserId);

  const folder = await VaultFolder.findOne({
    _id: new Types.ObjectId(folderId),
    userId: ownerObjectId,
  });

  if (!folder) {
    throw new ApiError(
      StatusCodes.NOT_FOUND,
      'Vault folder not found or you are not the owner'
    );
  }

  const alreadyShared = folder.sharedWith?.some(
    s => s.userId.toString() === targetUserId
  );

  if (!alreadyShared) {
    folder.sharedWith = folder.sharedWith || [];
    folder.sharedWith.push({
      userId: targetObjectId,
      sharedAt: new Date(),
      permission: 'VIEW',
    });
    await folder.save();
  }

  return folder;
};

const getSharedWithMeFolders = async (
  userId: string,
  query: { search?: string }
) => {
  const userObjectId = new Types.ObjectId(userId);
  const filter: Record<string, unknown> = {
    'sharedWith.userId': userObjectId,
    isArchived: false,
  };

  if (query.search) {
    filter.$or = [
      { name: { $regex: query.search, $options: 'i' } },
      { description: { $regex: query.search, $options: 'i' } },
      { location: { $regex: query.search, $options: 'i' } },
    ];
  }

  const folders = await VaultFolder.find(filter)
    .populate('userId', 'name role profilePicture image')
    .sort({ createdAt: -1 })
    .lean();

  const folderIds = folders.map(f => f._id);
  const items = await VaultItem.find({ folderId: { $in: folderIds } }).lean();

  const enrichedFolders = folders.map(folder => {
    const folderItems = items.filter(
      item => item.folderId.toString() === folder._id.toString()
    );

    const videoCount = folderItems.filter(
      i => i.fileType === 'VIDEO' || i.fileType === 'RECORDING'
    ).length;
    const audioCount = folderItems.filter(i => i.fileType === 'AUDIO').length;
    const imageCount = folderItems.filter(i => i.fileType === 'IMAGE').length;
    const docCount = folderItems.filter(i => i.fileType === 'DOCUMENT').length;

    const containedCategories = Array.from(
      new Set(folderItems.map(i => i.category))
    );
    const linkedMeetingIds = folderItems
      .map(i => i.meetingId?.toString())
      .filter((id): id is string => Boolean(id));

    return {
      ...folder,
      isReadOnly: true,
      sharedBy: folder.userId,
      itemCount: folderItems.length,
      linkedMeetingIds,
      counts: {
        video: videoCount,
        audio: audioCount,
        image: imageCount,
        doc: docCount,
      },
      containedCategories,
      itemSummary: {
        total: folderItems.length,
        videos: videoCount,
        audio: audioCount,
        images: imageCount,
        docs: docCount,
      },
    };
  });

  return enrichedFolders;
};

const getAllRecordings = async (userId: string) => {
  const userObjectId = new Types.ObjectId(userId);

  // 1. Fetch meetings where user is host (userId), participant (participantId), joined attorney, or joined participant
  // The recording will be added when host ends meeting (status: COMPLETED)
  const meetings = await Meeting.find({
    $or: [
      { userId: userObjectId },
      { participantId: userObjectId },
      { joinedAttorneys: userObjectId },
      { joinedParticipants: userObjectId },
    ],
    status: 'COMPLETED',
  })
    .populate('userId', 'name role profilePicture image phoneNumber')
    .populate('participantId', 'name role profilePicture image phoneNumber')
    .populate('joinedAttorneys', 'name role profilePicture image')
    .populate('joinedParticipants', 'name role profilePicture image phoneNumber')
    .populate('vaultFolderId', 'name category')
    .sort({ createdAt: -1 })
    .lean();

  const meetingObjectIds = meetings.map(m => m._id);

  // Ensure every meeting has a valid playback URL and category
  const normalizedMeetings = (
    meetings as unknown as Array<Record<string, unknown>>
  ).map((m) => {
    if (!m.recordingUrl || m.recordingUrl === '') {
      m.recordingUrl = `https://recordings.govia.ai/play/${m._id}`;
    }
    const cat = m.category as string | undefined;
    if (!cat || !['ENCOUNTER', 'EMERGENCY', 'CONSULTATION'].includes(cat)) {
      const topic = typeof m.topic === 'string' ? m.topic.toLowerCase() : '';
      m.category =
        m.meetingType === 'EMERGENCY'
          ? 'EMERGENCY'
          : topic.includes('police') ||
              topic.includes('encounter') ||
              topic.includes('govia')
            ? 'ENCOUNTER'
            : 'CONSULTATION';
    }
    const userObj = m.userId as { name?: string } | undefined;
    const participantObj = m.participantId as { name?: string } | undefined;
    const attorneys = m.joinedAttorneys as { name?: string }[] | undefined;
    const participants = m.joinedParticipants as { name?: string }[] | undefined;
    m.hostName = userObj?.name || 'Citizen';
    m.participantName =
      participantObj?.name ||
      attorneys?.[0]?.name ||
      participants?.[0]?.name ||
      'Responder';
    return m;
  });

  // 2. Fetch standalone vault items of type VIDEO or RECORDING (e.g. uploaded video files)
  // Exclude vault items that wrap an existing meeting to prevent duplicate recordings in Vault!
  const vaultRecordings = await VaultItem.find({
    userId: userObjectId,
    $or: [{ fileType: 'VIDEO' }, { fileType: 'RECORDING' }],
    $and: [
      {
        $or: [
          { meetingId: { $exists: false } },
          { meetingId: null },
          { meetingId: { $nin: meetingObjectIds } },
        ],
      },
    ],
  })
    .populate('folderId', 'name category')
    .sort({ createdAt: -1 })
    .lean();

  return {
    meetings: normalizedMeetings,
    vaultItems: vaultRecordings,
    all: [...normalizedMeetings, ...vaultRecordings],
  };
};

export const VaultService = {
  createFolder,
  getUserFolders,
  getFolderDetails,
  updateFolder,
  deleteFolder,
  uploadEvidence,
  linkMeetingToFolder,
  deleteItem,
  shareFolder,
  getSharedWithMeFolders,
  getAllRecordings,
};
