import { Types } from 'mongoose';
import { StatusCodes } from 'http-status-codes';
import ApiError from '../../../errors/ApiError';
import { USER_ROLES } from '../../../enums/user';
import { User } from '../user/user.model';
import { Subscription } from './subscription.model';
import { CitizenUsage } from './citizenUsage.model';
import {
  SUBSCRIPTION_PLAN,
  PAYMENT_PROVIDER,
} from './subscription.interface';
import { verifyAppleReceipt } from './appleIap.service';
import { verifyGooglePlaySubscription } from './googlePlay.service';

const getCurrentYearMonth = (): string => {
  return new Date().toISOString().slice(0, 7); // Format: 'YYYY-MM'
};

/**
 * Resolve user role reliably. If role is not provided in context,
 * fetch from database to guarantee non-citizen roles are never accidentally gated.
 */
const resolveUserRole = async (
  userId: string,
  userRole?: string
): Promise<string> => {
  if (userRole && userRole.trim().length > 0) {
    return userRole.toUpperCase();
  }
  try {
    const userDoc = await User.findById(userId).select('role').lean();
    if (userDoc?.role) {
      return userDoc.role.toUpperCase();
    }
  } catch (_error) {
    // Fallback to CITIZEN if lookup fails
  }
  return USER_ROLES.CITIZEN;
};

const isCitizenRole = (role: string): boolean => {
  const upper = role.toUpperCase();
  return upper === USER_ROLES.CITIZEN || upper === USER_ROLES.USER;
};

/**
 * Retrieve comprehensive subscription & quota state for a user.
 * Non-citizen roles (Attorneys, Police, Doctors, Admins, Bondsmen) are completely exempt.
 */
const getUserSubscriptionStatus = async (
  userId: string,
  userRole?: string
) => {
  const effectiveRole = await resolveUserRole(userId, userRole);
  const isCitizen = isCitizenRole(effectiveRole);

  // Non-citizen professional roles bypass all citizen subscription gates
  if (!isCitizen) {
    return {
      role: effectiveRole,
      isCitizen: false,
      needsSubscription: false,
      plan: 'EXEMPT',
      status: 'ACTIVE',
      isPremium: true,
      billingCycle: 'EXEMPT',
      startDate: null,
      endDate: null,
      autoRenew: false,
      monthlyUsage: {
        yearMonth: getCurrentYearMonth(),
        used: 0,
        limit: -1,
        remaining: -1,
        isLimitReached: false,
      },
      features: {
        canStartUnlimitedMeetings: true,
        canViewRecordings: true,
        hasDoctorSupport: true,
        hasPremiumAI: true,
      },
    };
  }

  const userObjectId = new Types.ObjectId(userId);
  const now = new Date();

  // Find latest active subscription
  let activeSub = await Subscription.findOne({
    userId: userObjectId,
    status: 'ACTIVE',
  }).sort({ createdAt: -1 });

  // Check if subscription has expired
  if (activeSub && activeSub.endDate && activeSub.endDate < now) {
    activeSub.status = 'EXPIRED';
    await activeSub.save();
    activeSub = null;
  }

  const isPremium =
    activeSub !== null &&
    (activeSub.plan === 'PREMIUM_MONTHLY' || activeSub.plan === 'PREMIUM_YEARLY');

  // Query usage for the current calendar month
  const yearMonth = getCurrentYearMonth();
  const usage = await CitizenUsage.findOne({
    userId: userObjectId,
    yearMonth,
  });

  const usedMeetings = usage ? usage.meetingCount : 0;
  const meetingLimit = 3;
  const remainingMeetings = isPremium
    ? -1
    : Math.max(0, meetingLimit - usedMeetings);

  return {
    role: USER_ROLES.CITIZEN,
    isCitizen: true,
    needsSubscription: true,
    plan: isPremium ? activeSub!.plan : 'FREE',
    status: isPremium ? 'ACTIVE' : 'FREE',
    isPremium,
    billingCycle: activeSub ? activeSub.billingCycle : 'NONE',
    startDate: activeSub ? activeSub.startDate : null,
    endDate: activeSub ? activeSub.endDate : null,
    autoRenew: activeSub ? activeSub.autoRenew : false,
    monthlyUsage: {
      yearMonth,
      used: usedMeetings,
      limit: isPremium ? -1 : meetingLimit,
      remaining: remainingMeetings,
      isLimitReached: !isPremium && usedMeetings >= meetingLimit,
    },
    features: {
      canStartUnlimitedMeetings: isPremium,
      canViewRecordings: isPremium,
      hasDoctorSupport: isPremium,
      hasPremiumAI: isPremium,
    },
  };
};

/**
 * Check if the user is authorized to start an emergency or govia meeting.
 * Citizens on FREE plan are capped at 3 meetings per calendar month.
 */
const checkCitizenMeetingQuota = async (
  userId: string,
  userRole?: string
): Promise<{
  allowed: boolean;
  reason?: string;
  used: number;
  limit: number;
  plan: string;
}> => {
  const effectiveRole = await resolveUserRole(userId, userRole);
  if (!isCitizenRole(effectiveRole)) {
    return { allowed: true, used: 0, limit: -1, plan: 'EXEMPT' };
  }

  const status = await getUserSubscriptionStatus(userId, effectiveRole);
  if (status.isPremium) {
    return {
      allowed: true,
      used: status.monthlyUsage.used,
      limit: -1,
      plan: status.plan,
    };
  }

  const used = status.monthlyUsage.used;
  const limit = 3;

  if (used >= limit) {
    return {
      allowed: false,
      reason: `You have reached your limit of ${limit} free emergency/Govia meetings this month. Upgrade to Premium for unlimited emergency protection.`,
      used,
      limit,
      plan: 'FREE',
    };
  }

  return {
    allowed: true,
    used,
    limit,
    plan: 'FREE',
  };
};

/**
 * Increment meeting usage for the citizen for the current calendar month.
 */
const incrementCitizenMeetingCount = async (
  userId: string,
  userRole?: string
): Promise<void> => {
  const effectiveRole = await resolveUserRole(userId, userRole);
  if (!isCitizenRole(effectiveRole)) {
    return;
  }

  const yearMonth = getCurrentYearMonth();
  await CitizenUsage.findOneAndUpdate(
    {
      userId: new Types.ObjectId(userId),
      yearMonth,
    },
    {
      $inc: { meetingCount: 1 },
      $set: { lastMeetingAt: new Date() },
    },
    {
      upsert: true,
      new: true,
    }
  );
};

/**
 * Returns available plans with pricing and features
 */
const getAvailablePlans = async () => {
  return [
    {
      id: 'free',
      name: 'Community Free',
      role: 'CITIZEN',
      price: 0,
      currency: 'USD',
      billingCycle: 'NONE',
      badge: 'Current Plan',
      description: 'Essential public safety coverage for community members.',
      features: [
        { title: 'Emergency Meetings', description: '3 free meetings per month', included: true },
        { title: 'GoVia AI Legal Assistant', description: 'Community Free AI model rotation', included: true },
        { title: 'Incident Logging & GPS', description: 'Standard incident location logging', included: true },
        { title: 'Cloud Video Recordings', description: 'Session video playback and archive', included: false },
        { title: 'Doctor & Mental Health', description: 'Direct confidential medical telehealth', included: false },
        { title: 'Priority Dispatch', description: 'High-priority attorney & bondsman routing', included: false },
      ],
    },
    {
      id: 'premium_monthly',
      name: 'Govia Premium (Monthly)',
      role: 'CITIZEN',
      price: 9.99,
      currency: 'USD',
      billingCycle: 'MONTHLY',
      badge: 'Popular',
      description: 'Comprehensive, unlimited safety and 24/7 medical & legal support.',
      features: [
        { title: 'Unlimited Emergency Meetings', description: 'Start instant encounters 24/7 with zero limits', included: true },
        { title: 'Full Cloud Video Vault', description: 'Stream, review, and download all session recordings', included: true },
        { title: '24/7 Doctor & Mental Health', description: 'Confidential chat & appointment booking with doctors', included: true },
        { title: 'Advanced Legal AI Copilot', description: 'High-speed GPT-4o / Claude legal reasoning', included: true },
        { title: 'Priority Dispatch', description: 'Top-tier alerts sent to verified attorneys and bondsmen', included: true },
      ],
    },
    {
      id: 'premium_yearly',
      name: 'Govia Premium (Yearly)',
      role: 'CITIZEN',
      price: 79.99,
      currency: 'USD',
      billingCycle: 'YEARLY',
      badge: 'Best Value • Save 33%',
      description: 'Our complete protection suite with 2 months free ($6.67/month equivalent).',
      features: [
        { title: 'All Monthly Premium Features', description: 'Full unlimited access across all modules', included: true },
        { title: 'Maximum Savings', description: 'Save $40 per year compared to monthly billing', included: true },
        { title: 'VIP Support & Evidence Export', description: 'Court-admissible tamper-proof evidence packages', included: true },
      ],
    },
  ];
};

/**
 * Handle In-App Purchases from Apple App Store or Google Play Store
 */
const verifyAndSubscribeIAP = async (
  userId: string,
  userRole: string | undefined,
  payload: {
    provider: PAYMENT_PROVIDER;
    productId: string;
    token: string;
  }
) => {
  const effectiveRole = await resolveUserRole(userId, userRole);
  if (!isCitizenRole(effectiveRole)) {
    return {
      message: 'Subscription is not required for your professional account.',
      isExempt: true,
      role: effectiveRole,
    };
  }

  const { provider, productId, token } = payload;
  const userObjectId = new Types.ObjectId(userId);

  const isYearly =
    productId.toLowerCase().includes('yearly') ||
    productId.toLowerCase().includes('annual');

  let verificationResult: {
    valid: boolean;
    productId: string;
    expiresDate?: Date;
    originalTransactionId?: string;
    message?: string;
  };

  if (provider === 'APPLE_IAP') {
    verificationResult = await verifyAppleReceipt(token, productId);
  } else if (provider === 'GOOGLE_PLAY') {
    verificationResult = await verifyGooglePlaySubscription(token, productId);
  } else {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid IAP payment provider');
  }

  if (!verificationResult.valid) {
    throw new ApiError(
      StatusCodes.PAYMENT_REQUIRED,
      verificationResult.message || 'In-App Purchase verification failed'
    );
  }

  // Deactivate any existing active subscriptions
  await Subscription.updateMany(
    { userId: userObjectId, status: 'ACTIVE' },
    { $set: { status: 'CANCELLED', autoRenew: false } }
  );

  const now = new Date();
  const calculatedEndDate =
    verificationResult.expiresDate ||
    new Date(now.getTime() + (isYearly ? 365 : 30) * 24 * 60 * 60 * 1000);

  const planType: SUBSCRIPTION_PLAN = isYearly
    ? 'PREMIUM_YEARLY'
    : 'PREMIUM_MONTHLY';

  const newSub = await Subscription.create({
    userId: userObjectId,
    role: effectiveRole || USER_ROLES.CITIZEN,
    plan: planType,
    status: 'ACTIVE',
    billingCycle: isYearly ? 'YEARLY' : 'MONTHLY',
    price: isYearly ? 79.99 : 9.99,
    currency: 'USD',
    startDate: now,
    endDate: calculatedEndDate,
    autoRenew: true,
    paymentProvider: provider,
    productId,
    purchaseToken: token,
    originalTransactionId: verificationResult.originalTransactionId,
  });

  return newSub;
};

/**
 * Direct subscription helper (for development, testing, or web checkouts)
 */
const subscribeManual = async (
  userId: string,
  userRole: string | undefined,
  plan: SUBSCRIPTION_PLAN,
  paymentProvider: PAYMENT_PROVIDER = 'MANUAL'
) => {
  const effectiveRole = await resolveUserRole(userId, userRole);
  if (!isCitizenRole(effectiveRole)) {
    return {
      message: 'Subscription is not required for your professional account.',
      isExempt: true,
      role: effectiveRole,
    };
  }

  const userObjectId = new Types.ObjectId(userId);

  if (plan === 'FREE') {
    await Subscription.updateMany(
      { userId: userObjectId, status: 'ACTIVE' },
      { $set: { status: 'CANCELLED', autoRenew: false } }
    );
    return { message: 'Switched to Community Free plan' };
  }

  const isYearly = plan === 'PREMIUM_YEARLY';
  const now = new Date();
  const endDate = new Date(
    now.getTime() + (isYearly ? 365 : 30) * 24 * 60 * 60 * 1000
  );

  // Deactivate old active subscriptions
  await Subscription.updateMany(
    { userId: userObjectId, status: 'ACTIVE' },
    { $set: { status: 'CANCELLED', autoRenew: false } }
  );

  const newSub = await Subscription.create({
    userId: userObjectId,
    role: effectiveRole || USER_ROLES.CITIZEN,
    plan,
    status: 'ACTIVE',
    billingCycle: isYearly ? 'YEARLY' : 'MONTHLY',
    price: isYearly ? 79.99 : 9.99,
    currency: 'USD',
    startDate: now,
    endDate,
    autoRenew: true,
    paymentProvider,
  });

  return newSub;
};

/**
 * Cancel auto-renew on active subscription
 */
const cancelSubscription = async (userId: string) => {
  const userObjectId = new Types.ObjectId(userId);
  const activeSub = await Subscription.findOne({
    userId: userObjectId,
    status: 'ACTIVE',
  });

  if (!activeSub) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'No active subscription found');
  }

  activeSub.autoRenew = false;
  await activeSub.save();

  return activeSub;
};

/**
 * Activate or extend a subscription via a redeemed Gift Code
 */
const activateGiftSubscription = async (
  userId: string,
  userRole: string | undefined,
  plan: SUBSCRIPTION_PLAN,
  durationDays: number,
  giftCode: string
) => {
  const effectiveRole = await resolveUserRole(userId, userRole);
  const userObjectId = new Types.ObjectId(userId);
  const now = new Date();

  // Find if user already has an active subscription
  const activeSub = await Subscription.findOne({
    userId: userObjectId,
    status: 'ACTIVE',
  }).sort({ createdAt: -1 });

  let calculatedEndDate: Date;

  if (activeSub && activeSub.endDate && activeSub.endDate > now) {
    // Extend from the current expiration date
    calculatedEndDate = new Date(
      activeSub.endDate.getTime() + durationDays * 24 * 60 * 60 * 1000
    );
    activeSub.endDate = calculatedEndDate;
    if (plan === 'PREMIUM_YEARLY') {
      activeSub.plan = 'PREMIUM_YEARLY';
      activeSub.billingCycle = 'YEARLY';
    }
    await activeSub.save();
    return activeSub;
  }

  // Deactivate any expired or older subscriptions
  await Subscription.updateMany(
    { userId: userObjectId, status: 'ACTIVE' },
    { $set: { status: 'CANCELLED', autoRenew: false } }
  );

  calculatedEndDate = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

  const isYearly = durationDays >= 365 || plan === 'PREMIUM_YEARLY';
  const newSub = await Subscription.create({
    userId: userObjectId,
    role: effectiveRole || USER_ROLES.CITIZEN,
    plan,
    status: 'ACTIVE',
    billingCycle: isYearly ? 'YEARLY' : 'MONTHLY',
    price: 0,
    currency: 'USD',
    startDate: now,
    endDate: calculatedEndDate,
    autoRenew: false, // Gift passes do not auto-renew on recipient's account
    paymentProvider: 'MANUAL',
    productId: `gift_code:${giftCode}`,
  });

  return newSub;
};

export const SubscriptionService = {
  getUserSubscriptionStatus,
  checkCitizenMeetingQuota,
  incrementCitizenMeetingCount,
  getAvailablePlans,
  verifyAndSubscribeIAP,
  subscribeManual,
  cancelSubscription,
  activateGiftSubscription,
};

