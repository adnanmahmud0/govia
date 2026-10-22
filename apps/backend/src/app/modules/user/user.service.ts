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
import { ReferralService } from '../referral/referral.service';
import { debug } from '../../../shared/debug';
import QueryBuilder from '../../builder/QueryBuilder';

const createUserToDB = async (
  payload: Partial<IUser> & { referredByCode?: string; inviteCode?: string }
): Promise<IUser> => {
  //set role if not provided
  if (!payload.role) payload.role = USER_ROLES.USER;

  const isCitizen =
    payload.role === USER_ROLES.USER || payload.role === USER_ROLES.CITIZEN;

  // Extract any incoming invite code entered by user
  let inviteCode = payload.referredByCode || payload.inviteCode;

  // If user entered referralCode in registration payload, check if it refers to another user
  if (payload.referralCode) {
    const existingReferrer = await User.findOne({
      referralCode: payload.referralCode.toUpperCase(),
    }).lean();
    if (existingReferrer) {
      inviteCode = payload.referralCode;
    }
  }

  // Assign citizen's own unique referral code
  if (isCitizen) {
    payload.referralCode = await ReferralService.generateUniqueReferralCode(
      payload.name
    );
  }

  const createUser = await User.create(payload);
  if (!createUser) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Failed to create user');
  }

  // If invited by another citizen, attribute points and bonuses
  if (isCitizen && inviteCode) {
    try {
      await ReferralService.attributeReferralOnRegister(
        createUser._id,
        inviteCode
      );
    } catch (_err) {
      // Non-blocking attribution
    }
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

const getAllUsersFromDB = async (
  query: Record<string, unknown>,
  currentUser?: JwtPayload
) => {
  const isAdmin =
    currentUser?.role === USER_ROLES.SUPER_ADMIN ||
    currentUser?.role === USER_ROLES.ADMIN;

  const filterQuery: Record<string, unknown> = { ...query };

  // Non-admins (Citizens, Users, Attorneys) can only query public provider/specialist roles
  if (!isAdmin) {
    const requestedRole = filterQuery.role ? String(filterQuery.role).toUpperCase() : '';
    const allowedPublicRoles: string[] = [
      USER_ROLES.MENTAL_HEALTH_PROFESSIONAL,
      USER_ROLES.ATTORNEY,
      USER_ROLES.BAIL_BONDSMAN,
      'DOCTOR',
    ];

    if (requestedRole && !allowedPublicRoles.includes(requestedRole)) {
      throw new ApiError(StatusCodes.FORBIDDEN, 'You do not have permission to browse this user category.');
    }

    if (requestedRole === 'DOCTOR' || requestedRole === USER_ROLES.MENTAL_HEALTH_PROFESSIONAL) {
      filterQuery.role = { $in: [USER_ROLES.MENTAL_HEALTH_PROFESSIONAL, 'DOCTOR'] };
    } else if (!requestedRole) {
      filterQuery.role = { $in: allowedPublicRoles };
    }

    filterQuery.status = 'active';
  }

  const userQuery = new QueryBuilder(User.find(), filterQuery)
    .search(['name', 'email', 'specialization', 'lawFirmName', 'companyName', 'officeName'])
    .filter()
    .sort()
    .paginate()
    .fields();

  if (!isAdmin) {
    userQuery.modelQuery.select(
      'name role subRole email image phoneNumber specialization companyName officeName lawFirmName shortDescription status verified createdAt'
    );
  }

  const result = await userQuery.modelQuery;
  const meta = await userQuery.getPaginationInfo();

  return {
    meta,
    data: result,
  };
};

const getSpecialistsFromDB = async (query: Record<string, unknown>) => {
  const page = Number(query.page) || 1;
  const limit = Number(query.limit) || 50;
  const skip = (page - 1) * limit;

  const role = query.role ? String(query.role).toUpperCase() : USER_ROLES.MENTAL_HEALTH_PROFESSIONAL;
  const filter: Record<string, unknown> = {
    status: 'active',
  };

  if (role === 'DOCTOR' || role === USER_ROLES.MENTAL_HEALTH_PROFESSIONAL) {
    filter.role = { $in: [USER_ROLES.MENTAL_HEALTH_PROFESSIONAL, 'DOCTOR'] };
  } else if (role) {
    filter.role = role;
  }

  if (query.specialty && query.specialty !== 'All') {
    filter.specialization = { $regex: String(query.specialty), $options: 'i' };
  }

  if (query.search) {
    const s = String(query.search).trim();
    filter.$or = [
      { name: { $regex: s, $options: 'i' } },
      { specialization: { $regex: s, $options: 'i' } },
      { companyName: { $regex: s, $options: 'i' } },
      { officeName: { $regex: s, $options: 'i' } },
      { shortDescription: { $regex: s, $options: 'i' } },
    ];
  }

  const total = await User.countDocuments(filter);
  const users = await User.find(filter)
    .select(
      'name role subRole email image phoneNumber specialization companyName officeName languagesSpoken shortDescription status verified createdAt'
    )
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

  const formatted = users.map((u, idx) => {
    const hash = u._id.toString().split('').reduce((acc: number, c: string) => acc + c.charCodeAt(0), 0);
    const rating = parseFloat((4.7 + (hash % 3) * 0.1).toFixed(1));
    const reviewCount = 45 + (hash % 110);
    const experienceYears = 6 + (hash % 12);

    return {
      _id: u._id.toString(),
      id: u._id.toString(),
      name: u.name,
      role: u.role,
      specialty: u.specialization || 'Crisis Counseling',
      title: u.subRole || (u.role === USER_ROLES.MENTAL_HEALTH_PROFESSIONAL ? 'Licensed Mental Health Specialist' : 'Healthcare Provider'),
      hospital: u.companyName || u.officeName || 'Govia Health Network',
      rating,
      reviewCount,
      experienceYears,
      isOnline: u.status === 'active',
      nextAvailable: idx % 2 === 0 ? 'Available Now' : 'Today, 3:00 PM',
      image: u.image || '',
      bio: u.shortDescription || `Dedicated ${u.role === USER_ROLES.MENTAL_HEALTH_PROFESSIONAL ? 'mental health professional' : 'specialist'} supporting community safety and emotional resilience.`,
      phoneNumber: u.phoneNumber || '',
      languagesSpoken: u.languagesSpoken || 'English',
    };
  });

  return {
    meta: {
      page,
      limit,
      total,
      totalPage: Math.ceil(total / limit),
    },
    data: formatted,
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

  // Badge number (exact or partial)
  queryConditions.push({
    badgeNumber: { $regex: new RegExp(cleaned, 'i') },
  });

  // License / LEO number
  queryConditions.push({
    licenseNumber: { $regex: new RegExp(cleaned, 'i') },
  });

  // assignedNumber / Patrol Unit / Car number
  queryConditions.push({
    assignedNumber: { $regex: new RegExp(`^${cleaned}$`, 'i') },
  });

  let user = await User.findOne({
    $or: queryConditions,
    status: 'active',
  })
    .select(
      '_id name email role image phoneNumber badgeNumber licenseNumber departmentOrPrecinct subRole lawFirmName officeName specialization companyName shortHexId assignedNumber'
    )
    .lean();

  // Fallback: If 8-character hex code, check if it matches the prefix or suffix of any user's ObjectId
  if (!user && /^[0-9a-fA-F]{8}$/.test(cleaned)) {
    const activeUsers = await User.find({ status: 'active' })
      .select(
        '_id name email role image phoneNumber badgeNumber licenseNumber departmentOrPrecinct subRole lawFirmName officeName specialization companyName shortHexId assignedNumber'
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

  // Check if this user currently has an active incident / emergency meeting (Type 1: ENCOUNTER, Type 2: EMERGENCY)
  // Note: Type 3 (CONSULTATION / SCHEDULED) is excluded from QR lookup per business requirements
  const activeMeeting = await Meeting.findOne({
    userId: user._id,
    status: 'ACTIVE',
    $or: [
      { category: { $in: ['ENCOUNTER', 'EMERGENCY'] } },
      { meetingType: 'EMERGENCY' },
      { topic: { $regex: /police|encounter|emergency|unsafe|stopped|govia/i } },
    ],
    category: { $ne: 'CONSULTATION' },
  })
    .select('_id roomName topic meetingType category status createdAt joinUrl token')
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
  getSpecialistsFromDB,
  getSingleUserFromDB,
  updateUserFromDB,
  deleteUserFromDB,
  lookupUserByIdentifier,
};

