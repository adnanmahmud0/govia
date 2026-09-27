import { StatusCodes } from 'http-status-codes';
import { Types } from 'mongoose';
import ApiError from '../../../errors/ApiError';
import { USER_ROLES } from '../../../enums/user';
import { User } from '../user/user.model';
import { Notification } from '../notification/notification.model';
import { socketHelper } from '../../../helpers/socketHelper';
import { IHeroHighlight } from './heroHighlight.interface';
import { HeroHighlight } from './heroHighlight.model';

type IPopulatedOfficer = {
  _id?: Types.ObjectId;
  name?: string;
  image?: string;
  badgeNumber?: string;
  departmentOrPrecinct?: string;
  subRole?: string;
  assignedNumber?: string;
};

const formatOfficerProfile = async (officer: Record<string, unknown>) => {
  const officerId = officer._id as Types.ObjectId;

  // Calculate officer stats
  const highlights = await HeroHighlight.find({ officerId }).lean();
  const totalCommendations = highlights.length;

  let avgRating = 4.9;
  let avgRespect = 9.0;
  let avgDeescalation = 9.5;
  let avgCommunication = 9.0;

  if (totalCommendations > 0) {
    const sumRespect = highlights.reduce((acc, h) => acc + (h.respectRating || 0), 0);
    const sumDeesc = highlights.reduce((acc, h) => acc + (h.deEscalationRating || 0), 0);
    const sumComm = highlights.reduce((acc, h) => acc + (h.communicationRating || 0), 0);

    avgRespect = +(sumRespect / totalCommendations).toFixed(1);
    avgDeescalation = +(sumDeesc / totalCommendations).toFixed(1);
    avgCommunication = +(sumComm / totalCommendations).toFixed(1);
    avgRating = +((avgRespect + avgDeescalation + avgCommunication) / 3 / 2).toFixed(1); // Scale to 5 stars
  }

  const idStr = String(officer._id);
  const shortHex =
    (officer.shortHexId as string) ||
    (idStr.length >= 8 ? idStr.slice(-8).toUpperCase() : idStr.toUpperCase());

  return {
    id: idStr,
    name: (officer.name as string) || 'Officer',
    rank: (officer.subRole as string) || 'Patrol Officer',
    badgeNumber: (officer.badgeNumber as string) || 'N/A',
    carNumber: (officer.assignedNumber as string) || 'N/A',
    agency:
      (officer.departmentOrPrecinct as string) ||
      (officer.officeName as string) ||
      'Metropolitan Police Department',
    licenseNumber: (officer.licenseNumber as string) || '',
    shortHexId: shortHex,
    image: (officer.image as string) || '',
    languages: (officer.languagesSpoken as string) || 'English',
    phoneNumber: (officer.phoneNumber as string) || '',
    rating: avgRating,
    respectRating: avgRespect,
    deescalationRating: avgDeescalation,
    communicationRating: avgCommunication,
    totalCommendations,
    verified: (officer.verified as boolean) ?? true,
    status: 'ACTIVE_DUTY',
  };
};

const getOfficersFromDB = async (searchQuery?: string) => {
  const query: Record<string, unknown> = {
    role: USER_ROLES.POLICE,
    status: 'active',
  };

  if (searchQuery && searchQuery.trim()) {
    const clean = searchQuery.trim();
    const regex = new RegExp(clean, 'i');
    query.$or = [
      { name: regex },
      { badgeNumber: regex },
      { assignedNumber: regex },
      { departmentOrPrecinct: regex },
      { licenseNumber: regex },
      { subRole: regex },
    ];
  }

  const officers = await User.find(query)
    .select(
      '_id name subRole badgeNumber assignedNumber departmentOrPrecinct licenseNumber image shortHexId languagesSpoken phoneNumber verified'
    )
    .sort({ name: 1 })
    .lean();

  const formatted = await Promise.all(officers.map(formatOfficerProfile));
  return formatted;
};

const lookupOfficerByIdentifier = async (rawIdentifier: string) => {
  if (!rawIdentifier || !rawIdentifier.trim()) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Officer identifier or QR payload is required');
  }

  let cleaned = rawIdentifier.trim();

  // Try parsing JSON if QR payload
  if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
    try {
      const parsed = JSON.parse(cleaned);
      if (parsed.id && typeof parsed.id === 'string') {
        cleaned = parsed.id.trim();
      } else if (parsed.shortId && typeof parsed.shortId === 'string') {
        cleaned = parsed.shortId.trim();
      } else if (parsed.badgeNumber && typeof parsed.badgeNumber === 'string') {
        cleaned = parsed.badgeNumber.trim();
      }
    } catch (_) {
      // ignore parse error and proceed with raw identifier
    }
  }

  if (cleaned.startsWith('#')) {
    cleaned = cleaned.substring(1).trim();
  }

  const conditions: Array<Record<string, unknown>> = [];

  if (Types.ObjectId.isValid(cleaned) && cleaned.length === 24) {
    conditions.push({ _id: new Types.ObjectId(cleaned) });
  }

  const cleanRegex = new RegExp(`^${cleaned}$`, 'i');
  const containsRegex = new RegExp(cleaned, 'i');

  conditions.push({ shortHexId: cleanRegex });
  conditions.push({ badgeNumber: cleanRegex });
  conditions.push({ badgeNumber: containsRegex });
  conditions.push({ licenseNumber: cleanRegex });
  conditions.push({ assignedNumber: cleanRegex });
  conditions.push({ name: containsRegex });

  let officer = await User.findOne({
    role: USER_ROLES.POLICE,
    status: 'active',
    $or: conditions,
  })
    .select(
      '_id name subRole badgeNumber assignedNumber departmentOrPrecinct licenseNumber image shortHexId languagesSpoken phoneNumber verified'
    )
    .lean();

  // Fallback: 8-char hex code prefix/suffix check
  if (!officer && /^[0-9a-fA-F]{8}$/.test(cleaned)) {
    const allPolice = await User.find({ role: USER_ROLES.POLICE, status: 'active' })
      .select(
        '_id name subRole badgeNumber assignedNumber departmentOrPrecinct licenseNumber image shortHexId languagesSpoken phoneNumber verified'
      )
      .lean();
    const target = cleaned.toLowerCase();
    officer =
      allPolice.find(
        u =>
          u.shortHexId?.toLowerCase() === target ||
          u._id.toString().toLowerCase().endsWith(target) ||
          u._id.toString().toLowerCase().startsWith(target)
      ) || null;
  }

  if (!officer) {
    throw new ApiError(StatusCodes.NOT_FOUND, `No police officer found matching "${cleaned}"`);
  }

  return formatOfficerProfile(officer);
};

const createHeroHighlightToDB = async (payload: IHeroHighlight) => {
  // If officerId is given, link and enhance metadata
  if (payload.officerId) {
    const officer = await User.findById(payload.officerId).lean();
    if (officer) {
      if (!payload.officerName || payload.officerName === 'Officer') {
        payload.officerName = officer.name;
      }
      if (!payload.agency) {
        payload.agency = officer.departmentOrPrecinct || officer.officeName || 'Police Department';
      }
      if (!payload.badgeNumber && officer.badgeNumber) {
        payload.badgeNumber = officer.badgeNumber;
      }
      if (!payload.carNumber && officer.assignedNumber) {
        payload.carNumber = officer.assignedNumber;
      }
      if (officer.image) {
        payload.officerAvatar = officer.image;
      }
      if (officer.subRole) {
        payload.officerRank = officer.subRole;
      }
    }
  }

  const result = await HeroHighlight.create(payload);

  // Send notification to officer if linked
  if (payload.officerId) {
    try {
      const citizen = await User.findById(payload.uploadedBy).select('name').lean();
      const citizenName = citizen?.name || 'A citizen';

      await Notification.create({
        userId: payload.officerId,
        type: 'highlight',
        title: '⭐ Community Hero Commendation!',
        subtitle: `${citizenName} highlighted your exceptional service, de-escalation, and conduct on GoVia.`,
        resourceType: 'system',
        resourceId: result._id.toString(),
        metadata: {
          highlightId: result._id.toString(),
          citizenName,
          respectRating: payload.respectRating,
          deEscalationRating: payload.deEscalationRating,
        },
        isRead: false,
      });

      socketHelper.emitToUser(payload.officerId.toString(), 'notification', {
        title: '⭐ Community Hero Commendation!',
        message: `${citizenName} highlighted your service on GoVia.`,
      });
    } catch (_) {
      // ignore notification delivery failure
    }
  }

  const populated = await HeroHighlight.findById(result._id)
    .populate('uploadedBy', 'name email image role')
    .populate('officerId', 'name image badgeNumber departmentOrPrecinct subRole assignedNumber');

  return populated;
};

const getHeroHighlightsFromDB = async () => {
  const result = await HeroHighlight.find()
    .sort({ createdAt: -1 })
    .populate('uploadedBy', 'name email image role')
    .populate('officerId', 'name image badgeNumber departmentOrPrecinct subRole assignedNumber')
    .lean();

  return result.map(h => {
    const popOfficer = h.officerId as IPopulatedOfficer | undefined;
    const hRecord = h as Record<string, unknown>;

    return {
      id: h._id.toString(),
      officerName: h.officerName,
      officerRank: h.officerRank || popOfficer?.subRole || 'Officer',
      badgeNumber: h.badgeNumber || popOfficer?.badgeNumber || '',
      agency: h.agency || popOfficer?.departmentOrPrecinct || '',
      carNumber: h.carNumber || popOfficer?.assignedNumber || '',
      officerAvatar: h.officerAvatar || popOfficer?.image || '',
      officerId: popOfficer?._id ? popOfficer._id.toString() : null,
      story: h.whatDidOfficerDoWell,
      incidentDate: h.incidentDate,
      incidentLocation: h.incidentLocation,
      respectRating: h.respectRating,
      deescalationRating: h.deEscalationRating,
      communicationRating: h.communicationRating,
      likes: h.likes || (h.salutes ? h.salutes.length : 0),
      salutes: h.salutes || [],
      uploadedBy: h.uploadedBy,
      createdAt: (hRecord.createdAt as Date) || new Date(),
    };
  });
};

const getSingleHeroHighlightFromDB = async (id: string) => {
  const result = await HeroHighlight.findById(id)
    .populate('uploadedBy', 'name email image')
    .populate('officerId', 'name image badgeNumber departmentOrPrecinct subRole assignedNumber');
  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Hero Highlight not found');
  }
  return result;
};

const toggleSaluteInDB = async (highlightId: string, userId: string) => {
  const highlight = await HeroHighlight.findById(highlightId);
  if (!highlight) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Hero Highlight not found');
  }

  const userObjId = new Types.ObjectId(userId);
  highlight.salutes = highlight.salutes || [];

  const existingIdx = highlight.salutes.findIndex(id => id.toString() === userId);
  let saluted = false;

  if (existingIdx > -1) {
    highlight.salutes.splice(existingIdx, 1);
    saluted = false;
  } else {
    highlight.salutes.push(userObjId);
    saluted = true;
  }

  highlight.likes = highlight.salutes.length;
  await highlight.save();

  return {
    highlightId,
    likes: highlight.likes,
    saluted,
  };
};

export const HeroHighlightService = {
  getOfficersFromDB,
  lookupOfficerByIdentifier,
  createHeroHighlightToDB,
  getHeroHighlightsFromDB,
  getSingleHeroHighlightFromDB,
  toggleSaluteInDB,
};
