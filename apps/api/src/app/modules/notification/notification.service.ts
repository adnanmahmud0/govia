import { Types } from 'mongoose';
import { StatusCodes } from 'http-status-codes';
import ApiError from '../../../errors/ApiError';
import { socketHelper } from '../../../helpers/socketHelper';
import { User } from '../user/user.model';
import { Notification } from './notification.model';
import { INotification } from './notification.interface';

/**
 * Returns role-specific starter notifications when a user has none.
 */
const getInitialNotificationsForRole = (
  userId: Types.ObjectId,
  role: string,
  userName = 'User'
): Partial<INotification>[] => {
  const upperRole = role.toUpperCase();
  const now = new Date();

  if (upperRole === 'POLICE') {
    const cleanName = userName.replace(/^Officer\s+/i, '');
    return [
      {
        userId,
        type: 'dispatch',
        title: '🚨 Sector Dispatch Monitoring Online',
        subtitle: `Officer ${cleanName}, unit dispatch telemetry is active for Central Metro Division.`,
        resourceType: 'system',
        isRead: false,
        createdAt: new Date(now.getTime() - 10 * 60 * 1000),
      },
      {
        userId,
        type: 'duty',
        title: '📋 Department Duty Schedule',
        subtitle: 'Duty briefings and scheduled consultations with department specialists are ready.',
        resourceType: 'meeting',
        isRead: false,
        createdAt: new Date(now.getTime() - 45 * 60 * 1000),
      },
      {
        userId,
        type: 'encounter',
        title: '📹 Evidence Archiving Online',
        subtitle: 'Encounter video recordings and officer notes are automatically synced with Govia Vault.',
        resourceType: 'vault',
        isRead: true,
        createdAt: new Date(now.getTime() - 2 * 3600 * 1000),
      },
      {
        userId,
        type: 'system',
        title: '🛡️ Officer Safety Protocol',
        subtitle: 'Emergency stop broadcast network connected. Live GPS coordinates enabled for field units.',
        resourceType: 'system',
        isRead: true,
        createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
      },
    ];
  }

  if (upperRole === 'MENTAL_HEALTH_PROFESSIONAL' || upperRole === 'DOCTOR') {
    const cleanName = userName.replace(/^Dr\.?\s+/i, '');
    return [
      {
        userId,
        type: 'medical',
        title: '🩺 Crisis De-escalation Network Online',
        subtitle: `Dr. ${cleanName}, clinical triage channels are open for acute trauma and crisis consultations.`,
        resourceType: 'system',
        isRead: false,
        createdAt: new Date(now.getTime() - 8 * 60 * 1000),
      },
      {
        userId,
        type: 'consultation',
        title: '📅 Clinical Telehealth Hub',
        subtitle: 'Consultations scheduled in chat rooms will automatically synchronize to your Schedule tab.',
        resourceType: 'meeting',
        isRead: false,
        createdAt: new Date(now.getTime() - 35 * 60 * 1000),
      },
      {
        userId,
        type: 'vault',
        title: '🔒 HIPAA Evidence Vault',
        subtitle: 'Patient telehealth recordings and clinical notes are protected with end-to-end encryption.',
        resourceType: 'vault',
        isRead: true,
        createdAt: new Date(now.getTime() - 3 * 3600 * 1000),
      },
      {
        userId,
        type: 'system',
        title: '🌿 Community Wellness Network',
        subtitle: 'Your crisis intervention profile is active and discoverable by citizens seeking support.',
        resourceType: 'system',
        isRead: true,
        createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
      },
    ];
  }

  if (upperRole === 'ATTORNEY') {
    return [
      {
        userId,
        type: 'legal',
        title: '⚖️ Emergency Defense Standby Active',
        subtitle: 'Your legal chambers are on standby for citizen traffic stops, detentions, and encounters.',
        resourceType: 'system',
        isRead: false,
        createdAt: new Date(now.getTime() - 12 * 60 * 1000),
      },
      {
        userId,
        type: 'consultation',
        title: '📅 Client Legal Consultations',
        subtitle: 'Clients can arrange legal consultations directly via chat. Scheduled video hearings sync here.',
        resourceType: 'meeting',
        isRead: false,
        createdAt: new Date(now.getTime() - 50 * 60 * 1000),
      },
      {
        userId,
        type: 'vault',
        title: '📁 Evidence Vault & Case Files',
        subtitle: 'Review client encounter video recordings and verified witness statements in the Evidence Vault.',
        resourceType: 'vault',
        isRead: true,
        createdAt: new Date(now.getTime() - 4 * 3600 * 1000),
      },
      {
        userId,
        type: 'compliance',
        title: '🏛️ Bar Defense Verification',
        subtitle: 'Your active bar credentials have been verified for expedited representation.',
        resourceType: 'system',
        isRead: true,
        createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
      },
    ];
  }

  if (upperRole === 'BAIL_BONDSMAN') {
    return [
      {
        userId,
        type: 'bail',
        title: '🏛️ Surety & Bail Dispatch Connected',
        subtitle: 'Surety network active. Receive instant requests for bail bond verification and detainee release.',
        resourceType: 'system',
        isRead: false,
        createdAt: new Date(now.getTime() - 15 * 60 * 1000),
      },
      {
        userId,
        type: 'consultation',
        title: '📅 Bail Consultation Center',
        subtitle: 'Consultations scheduled with clients or indemnitors in chat will appear on your Schedule tab.',
        resourceType: 'meeting',
        isRead: false,
        createdAt: new Date(now.getTime() - 40 * 60 * 1000),
      },
      {
        userId,
        type: 'vault',
        title: '📁 Collateral & Indemnity Vault',
        subtitle: 'Access and manage collateral documentation and court filings securely in the Evidence Vault.',
        resourceType: 'vault',
        isRead: true,
        createdAt: new Date(now.getTime() - 2 * 3600 * 1000),
      },
      {
        userId,
        type: 'court',
        title: '⚖️ Court Registry Tracking',
        subtitle: 'Track municipal court appearances and surety compliance updates in real time.',
        resourceType: 'system',
        isRead: true,
        createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
      },
    ];
  }

  // DEFAULT / CITIZEN
  return [
    {
      userId,
      type: 'emergency',
      title: '🛡️ Govia Active Protection Online',
      subtitle: 'Your emergency stop button is armed. Responders, video recording, and live GPS are ready.',
      resourceType: 'system',
      isRead: false,
      createdAt: new Date(now.getTime() - 5 * 60 * 1000),
    },
    {
      userId,
      type: 'medical',
      title: '🩺 Mental Health & Clinical Care',
      subtitle: 'Verified doctors and therapists are available for confidential telehealth checkups via chat.',
      resourceType: 'meeting',
      isRead: false,
      createdAt: new Date(now.getTime() - 30 * 60 * 1000),
    },
    {
      userId,
      type: 'legal',
      title: '⚖️ Legal Counsel & Defense',
      subtitle: 'Licensed defense attorneys are on standby to protect your constitutional rights during encounters.',
      resourceType: 'meeting',
      isRead: true,
      createdAt: new Date(now.getTime() - 2 * 3600 * 1000),
    },
    {
      userId,
      type: 'vault',
      title: '📁 Evidence Vault Secured',
      subtitle: 'Your personal vault is encrypted. All recordings and legal documents are protected.',
      resourceType: 'vault',
      isRead: true,
      createdAt: new Date(now.getTime() - 24 * 3600 * 1000),
    },
  ];
};

const getNotifications = async (
  userId: string,
  userRole: string,
  page = 1,
  limit = 20
) => {
  const userObjectId = new Types.ObjectId(userId);

  // Check if user has any notifications; if none, auto-seed realistic role-specific notifications
  const existingCount = await Notification.countDocuments({ userId: userObjectId });
  if (existingCount === 0) {
    const userDoc = await User.findById(userId);
    const initialList = getInitialNotificationsForRole(
      userObjectId,
      userRole,
      userDoc?.name || 'User'
    );
    await Notification.insertMany(initialList);
  }

  const skip = (page - 1) * limit;

  const [notifications, total, unreadCount] = await Promise.all([
    Notification.find({ userId: userObjectId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Notification.countDocuments({ userId: userObjectId }),
    Notification.countDocuments({ userId: userObjectId, isRead: false }),
  ]);

  return {
    data: notifications,
    meta: {
      page,
      limit,
      total,
      unreadCount,
      hasMore: skip + notifications.length < total,
    },
  };
};

const markAsRead = async (userId: string, notificationId: string) => {
  if (!Types.ObjectId.isValid(notificationId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid notification ID');
  }

  const result = await Notification.findOneAndUpdate(
    { _id: new Types.ObjectId(notificationId), userId: new Types.ObjectId(userId) },
    { isRead: true, readAt: new Date() },
    { new: true }
  );

  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Notification not found');
  }

  return result;
};

const markAllAsRead = async (userId: string) => {
  const userObjectId = new Types.ObjectId(userId);
  await Notification.updateMany(
    { userId: userObjectId, isRead: false },
    { isRead: true, readAt: new Date() }
  );
  return { success: true };
};

const deleteNotification = async (userId: string, notificationId: string) => {
  if (!Types.ObjectId.isValid(notificationId)) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid notification ID');
  }

  const result = await Notification.findOneAndDelete({
    _id: new Types.ObjectId(notificationId),
    userId: new Types.ObjectId(userId),
  });

  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Notification not found');
  }

  return { success: true };
};

/**
 * Creates and delivers a persistent real-time notification to a user.
 */
const createNotification = async (payload: {
  userId: string | Types.ObjectId;
  type: string;
  title: string;
  subtitle: string;
  resourceType?: string;
  resourceId?: string;
  link?: { label: string; url: string };
  icon?: string;
}) => {
  try {
    const userObjectId =
      typeof payload.userId === 'string'
        ? new Types.ObjectId(payload.userId)
        : payload.userId;

    const notif = await Notification.create({
      userId: userObjectId,
      type: payload.type,
      title: payload.title,
      subtitle: payload.subtitle,
      resourceType: payload.resourceType || 'system',
      resourceId: payload.resourceId || '',
      link: payload.link,
      icon: payload.icon,
      isRead: false,
    });

    const notifObj = notif.toObject();

    // Real-time socket emission to user's private socket room
    socketHelper.emitToUser(
      userObjectId.toString(),
      'new_notification',
      notifObj
    );

    return notif;
  } catch (error) {
    console.error('Failed to create notification:', error);
    return null;
  }
};

/**
 * Creates and delivers notifications to all active users with a specified role.
 */
const createRoleNotification = async (
  targetRole: string,
  payload: {
    type: string;
    title: string;
    subtitle: string;
    resourceType?: string;
    resourceId?: string;
    link?: { label: string; url: string };
    icon?: string;
  },
  excludeUserId?: string
) => {
  try {
    const filter: any = { role: targetRole, status: 'active' };
    if (excludeUserId && Types.ObjectId.isValid(excludeUserId)) {
      filter._id = { $ne: new Types.ObjectId(excludeUserId) };
    }

    const users = await User.find(filter, { _id: 1 });
    if (users.length === 0) return [];

    const notifs = users.map(u => ({
      userId: u._id,
      type: payload.type,
      title: payload.title,
      subtitle: payload.subtitle,
      resourceType: payload.resourceType || 'system',
      resourceId: payload.resourceId || '',
      link: payload.link,
      icon: payload.icon,
      isRead: false,
    }));

    const created = await Notification.insertMany(notifs);

    // Emit socket alert to role channel
    socketHelper.emitToRole(targetRole, 'new_notification', payload);

    return created;
  } catch (error) {
    console.error(`Failed to dispatch notifications to role ${targetRole}:`, error);
    return [];
  }
};

export const NotificationService = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  createNotification,
  createRoleNotification,
};
