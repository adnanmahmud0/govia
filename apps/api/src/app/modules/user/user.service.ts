import { StatusCodes } from 'http-status-codes';
import { JwtPayload } from 'jsonwebtoken';
import { Types } from 'mongoose';
import { USER_ROLES } from '../../../enums/user';
import ApiError from '../../../errors/ApiError';
import { emailHelper } from '../../../helpers/emailHelper';
import { emailTemplate } from '../../../shared/emailTemplate';
import unlinkFile from '../../../shared/unlinkFile';
import generateOTP from '../../../util/generateOTP';
import { Meeting } from '../meeting/meeting.model';
import { IUser } from './user.interface';
import { User } from './user.model';
import { debug } from '../../../shared/debug';
import QueryBuilder from '../../builder/QueryBuilder';

const createUserToDB = async (payload: Partial<IUser>): Promise<IUser> => {
  //set role if not provided
  if (!payload.role) payload.role = USER_ROLES.USER;
  const createUser = await User.create(payload);
  if (!createUser) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Failed to create user');
  }

  //send email
  const otp = generateOTP();
  debug('user.register.otp_created', { email: createUser.email, otp });
  const values = {
    name: createUser.name,
    otp: otp,
    email: createUser.email!,
  };
  const createAccountTemplate = emailTemplate.createAccount(values);
  emailHelper.sendEmail(createAccountTemplate);
  debug('user.register.email_send_attempt', { email: createUser.email });

  //save to DB
  const authentication = {
    oneTimeCode: otp,
    expireAt: new Date(Date.now() + 3 * 60000),
  };
  await User.findOneAndUpdate(
    { _id: createUser._id },
    { $set: { authentication } }
  );
  debug('user.register.otp_saved', { email: createUser.email });

  return createUser;
};

const getUserProfileFromDB = async (
  user: JwtPayload
): Promise<Partial<IUser>> => {
  const { id } = user;
  const isExistUser = await User.isExistUserById(id);
  if (!isExistUser) {
    throw new ApiError(StatusCodes.BAD_REQUEST, "User doesn't exist!");
  }

  return isExistUser;
};

const updateProfileToDB = async (
  user: JwtPayload,
  payload: Partial<IUser>
): Promise<Partial<IUser | null>> => {
  const { id } = user;
  const isExistUser = await User.isExistUserById(id);
  if (!isExistUser) {
    throw new ApiError(StatusCodes.BAD_REQUEST, "User doesn't exist!");
  }

  //unlink file here
  if (payload.image) {
    if (isExistUser.image) {
      unlinkFile(isExistUser.image);
    }
  }

  const updateDoc = await User.findOneAndUpdate({ _id: id }, payload, {
    new: true,
  });

  return updateDoc;
};



const createUserByAdminToDB = async (payload: Partial<IUser>): Promise<IUser> => {
  payload.verified = true; // Admin created users are instantly verified
  const createUser = await User.create(payload);
  if (!createUser) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Failed to create user');
  }
  return createUser;
};

const getAllUsersFromDB = async (query: Record<string, unknown>) => {
  const userQuery = new QueryBuilder(User.find(), query)
    .search(['name', 'email'])
    .filter()
    .sort()
    .paginate()
    .fields();

  const result = await userQuery.modelQuery;
  const meta = await userQuery.getPaginationInfo();

  return {
    meta,
    data: result,
  };
};

const getSingleUserFromDB = async (id: string): Promise<IUser | null> => {
  const user = await User.findById(id);
  if (!user) {
    throw new ApiError(StatusCodes.NOT_FOUND, "User doesn't exist!");
  }
  return user;
};

const updateUserFromDB = async (
  id: string,
  payload: Partial<IUser>
): Promise<IUser | null> => {
  const isExistUser = await User.findById(id);
  if (!isExistUser) {
    throw new ApiError(StatusCodes.NOT_FOUND, "User doesn't exist!");
  }

  //unlink file here if image updated
  if (payload.image && isExistUser.image) {
    unlinkFile(isExistUser.image);
  }

  const updateDoc = await User.findByIdAndUpdate(id, payload, {
    new: true,
  });

  return updateDoc;
};

const deleteUserFromDB = async (id: string): Promise<IUser | null> => {
  const isExistUser = await User.findById(id);
  if (!isExistUser) {
    throw new ApiError(StatusCodes.NOT_FOUND, "User doesn't exist!");
  }

  if (isExistUser.image) {
    unlinkFile(isExistUser.image);
  }

  const deletedUser = await User.findByIdAndDelete(id);
  return deletedUser;
};

const lookupUserByIdentifier = async (rawIdentifier: string) => {
  if (!rawIdentifier || !rawIdentifier.trim()) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'User identifier or QR payload is required');
  }

  let cleaned = rawIdentifier.trim();

  // Try parsing JSON if identifier comes from GoVia QR card payload
  if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
    try {
      const parsed = JSON.parse(cleaned);
      if (parsed.id && typeof parsed.id === 'string') {
        cleaned = parsed.id.trim();
      } else if (parsed.shortId && typeof parsed.shortId === 'string') {
        cleaned = parsed.shortId.trim();
      }
    } catch (_) {
      // Not JSON, continue with raw string
    }
  }

  // Strip leading '#' if present (e.g. '#e3d7a82b')
  if (cleaned.startsWith('#')) {
    cleaned = cleaned.substring(1).trim();
  }

  const queryConditions: Array<Record<string, unknown>> = [];

  if (Types.ObjectId.isValid(cleaned) && cleaned.length === 24) {
    queryConditions.push({ _id: new Types.ObjectId(cleaned) });
  }

  // Exact or case-insensitive shortHexId
  queryConditions.push({
    shortHexId: { $regex: new RegExp(`^${cleaned}$`, 'i') },
  });

  // assignedNumber
  queryConditions.push({ assignedNumber: cleaned });

  let user = await User.findOne({
    $or: queryConditions,
    status: 'active',
  })
    .select(
      '_id name email role image phoneNumber badgeNumber lawFirmName officeName specialization companyName shortHexId assignedNumber'
    )
    .lean();

  // Fallback: If 8-character hex code, check if it matches the prefix or suffix of any user's ObjectId
  if (!user && /^[0-9a-fA-F]{8}$/.test(cleaned)) {
    const activeUsers = await User.find({ status: 'active' })
      .select(
        '_id name email role image phoneNumber badgeNumber lawFirmName officeName specialization companyName shortHexId assignedNumber'
      )
      .lean();

    const target = cleaned.toLowerCase();
    user =
      activeUsers.find(
        u =>
          u.shortHexId?.toLowerCase() === target ||
          u._id.toString().toLowerCase().endsWith(target) ||
          u._id.toString().toLowerCase().startsWith(target)
      ) || null;
  }

  if (!user) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'No user found with the provided ID or QR card');
  }

  // Check if this user currently has an active incident / emergency meeting
  const activeMeeting = await Meeting.findOne({
    userId: user._id,
    status: 'ACTIVE',
  })
    .select('_id roomName topic meetingType status createdAt joinUrl token')
    .lean();

  return {
    ...user,
    activeMeeting: activeMeeting || null,
  };
};

export const UserService = {
  createUserToDB,
  getUserProfileFromDB,
  updateProfileToDB,
  createUserByAdminToDB,
  getAllUsersFromDB,
  getSingleUserFromDB,
  updateUserFromDB,
  deleteUserFromDB,
  lookupUserByIdentifier,
};

