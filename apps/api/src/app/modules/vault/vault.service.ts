import { StatusCodes } from 'http-status-codes';
import { Types } from 'mongoose';
import ApiError from '../../../errors/ApiError';
import { Meeting } from '../meeting/meeting.model';
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
  const filter: any = {
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

    return {
      ...folder,
      itemCount: folderItems.length,
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
  const folder = await VaultFolder.findOne({
    _id: new Types.ObjectId(folderId),
    userId: new Types.ObjectId(userId),
  }).lean();

  if (!folder) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Vault folder not found');
  }

  const items = await VaultItem.find({
    folderId: new Types.ObjectId(folderId),
    userId: new Types.ObjectId(userId),
  })
    .sort({ createdAt: -1 })
    .lean();

  return {
    folder,
    items,
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
  uploadedFiles: any,
  payload: { title?: string; description?: string; category?: VaultCategory }
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
  const fileList: any[] = [];
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
    let fileType: VaultItemType = 'DOCUMENT';
    if (file.mimetype.startsWith('image/')) {
      fileType = 'IMAGE';
    } else if (file.mimetype.startsWith('video/')) {
      fileType = 'VIDEO';
    } else if (file.mimetype.startsWith('audio/')) {
      fileType = 'AUDIO';
    }

    const relativePath = `/uploads/${file.fieldname === 'image' ? 'image' : file.fieldname === 'media' ? 'media' : 'doc'}/${file.filename}`;

    itemsToCreate.push({
      userId: new Types.ObjectId(userId),
      folderId: new Types.ObjectId(folderId),
      title: payload.title || file.originalname || 'Uploaded Evidence',
      description: payload.description || '',
      category: payload.category || folder.category || 'UPLOADED',
      fileType,
      fileUrl: relativePath,
      fileSize: file.size,
      mimeType: file.mimetype,
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
  const folder = await VaultFolder.findOne({
    _id: new Types.ObjectId(payload.folderId),
    userId: new Types.ObjectId(userId),
  });

  if (!folder) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Target vault folder not found');
  }

  const meeting = await Meeting.findById(payload.meetingId);
  if (!meeting) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Meeting record not found');
  }

  const recordingUrl = meeting.recordingUrl || meeting.joinUrl || '';
  const duration = meeting.durationMinutes
    ? `${meeting.durationMinutes} mins`
    : '';

  const item = await VaultItem.create({
    userId: new Types.ObjectId(userId),
    folderId: new Types.ObjectId(payload.folderId),
    title: payload.title || meeting.topic || 'Consultation Session Recording',
    description: payload.description || meeting.agenda || 'Recorded consultation session from GoVia schedule.',
    category: 'CONSULTATION',
    fileType: 'RECORDING',
    fileUrl: recordingUrl,
    duration,
    meetingId: meeting._id,
  });

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

export const VaultService = {
  createFolder,
  getUserFolders,
  getFolderDetails,
  updateFolder,
  deleteFolder,
  uploadEvidence,
  linkMeetingToFolder,
  deleteItem,
};
