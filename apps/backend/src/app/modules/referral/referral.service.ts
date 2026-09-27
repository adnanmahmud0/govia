import crypto from 'crypto';
import { Types } from 'mongoose';
import { StatusCodes } from 'http-status-codes';
import ApiError from '../../../errors/ApiError';
import { USER_ROLES } from '../../../enums/user';
import { User } from '../user/user.model';
import { Referral } from './referral.model';
import { PointTransaction } from './pointTransaction.model';
import { GiftCode } from '../giftPlan/giftPlan.model';
import { SubscriptionService } from '../subscription/subscription.service';
import { Notification } from '../notification/notification.model';
import {
  REFERRAL_CONSTANTS,
  REWARD_CATALOG,
} from './referral.constant';
import {
  IReferralSummary,
  IRewardCatalogItem,
} from './referral.interface';

/**
 * Generate a clean, unique alphanumeric referral code for a citizen
 */
const generateUniqueReferralCode = async (userName?: string): Promise<string> => {
  const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  let basePrefix = 'GOVIA';

  if (userName) {
    const cleaned = userName.replace(/[^a-zA-Z]/g, '').toUpperCase();
    if (cleaned.length >= 3) {
      basePrefix = cleaned.slice(0, 5);
    }
  }

  let isUnique = false;
  let finalCode = '';

  while (!isUnique) {
    let suffix = '';
    const bytes = crypto.randomBytes(4);
    for (let i = 0; i < 4; i++) {
      suffix += chars[bytes[i] % chars.length];
    }
    finalCode = `${basePrefix}${suffix}`;

    const existing = await User.findOne({ referralCode: finalCode }).lean();
    if (!existing) {
      isUnique = true;
    }
  }

  return finalCode;
};

/**
 * Calculate ambassador tier based on lifetime points
 */
const calculateTier = (lifetimePoints: number): {
  tier: 'BRONZE' | 'SILVER' | 'GOLD' | 'PLATINUM';
  tierNextTarget: number;
} => {
  if (lifetimePoints >= 3000) {
    return { tier: 'PLATINUM', tierNextTarget: 5000 };
  }
  if (lifetimePoints >= 1500) {
    return { tier: 'GOLD', tierNextTarget: 3000 };
  }
  if (lifetimePoints >= 500) {
    return { tier: 'SILVER', tierNextTarget: 1500 };
  }
  return { tier: 'BRONZE', tierNextTarget: 500 };
};

/**
 * Get referral summary strictly for Citizen users
 */
const getReferralSummary = async (userId: string): Promise<IReferralSummary> => {
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'User not found');
  }

  const role = user.role?.toUpperCase();
  if (role !== USER_ROLES.CITIZEN && role !== USER_ROLES.USER) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'Referral points and rewards are strictly available for Citizens only.'
    );
  }

  // If user does not have a referral code yet, create one
  if (!user.referralCode) {
    user.referralCode = await generateUniqueReferralCode(user.name);
    await user.save();
  }

  const pointsBalance = user.referralPoints || 0;
  const lifetimePoints = user.lifetimeReferralPoints || 0;
  const referralCount = user.referralCount || 0;

  const { tier, tierNextTarget } = calculateTier(lifetimePoints);
  const referralLink = `${REFERRAL_CONSTANTS.BASE_WEB_URL}?ref=${user.referralCode}`;

  return {
    referralCode: user.referralCode,
    referralLink,
    pointsBalance,
    lifetimePoints,
    referralCount,
    tier,
    tierNextTarget,
  };
};

/**
 * Get paginated list of referred citizens
 */
const getReferralHistory = async (
  userId: string,
  query: Record<string, unknown>
) => {
  const page = Number(query.page) || 1;
  const limit = Math.min(Number(query.limit) || 20, 100);
  const skip = (page - 1) * limit;

  const total = await Referral.countDocuments({ referrerId: userId });
  const referrals = await Referral.find({ referrerId: userId })
    .populate('refereeId', 'name email image role createdAt')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

  return {
    meta: {
      page,
      limit,
      total,
      totalPage: Math.ceil(total / limit),
    },
    data: referrals,
  };
};

/**
 * Get available redeemable rewards
 */
const getRewardsCatalog = async (): Promise<IRewardCatalogItem[]> => {
  return REWARD_CATALOG;
};

/**
 * Redeem reward using citizen points
 */
const redeemReward = async (userId: string, rewardId: string) => {
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'User not found');
  }

  const role = user.role?.toUpperCase();
  if (role !== USER_ROLES.CITIZEN && role !== USER_ROLES.USER) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'Reward redemption is strictly reserved for Citizens.'
    );
  }

  const reward = REWARD_CATALOG.find(r => r.id === rewardId);
  if (!reward) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid reward selected.');
  }

  const currentPoints = user.referralPoints || 0;
  if (currentPoints < reward.pointsCost) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      `Insufficient points. You have ${currentPoints} points, but this reward requires ${reward.pointsCost} points.`
    );
  }

  // Deduct points
  const newBalance = currentPoints - reward.pointsCost;
  user.referralPoints = newBalance;
  await user.save();

  const redemptionDetails: Record<string, unknown> = {
    rewardId: reward.id,
    rewardTitle: reward.title,
    pointsDeducted: reward.pointsCost,
    newBalance,
  };

  // Execute Grounded Reward Action
  if (reward.actionType === 'ACTIVATE_SUBSCRIPTION') {
    // 30-day GoVia Plus subscription extension
    await SubscriptionService.activateGiftSubscription(
      userId,
      USER_ROLES.CITIZEN,
      'PREMIUM_MONTHLY',
      30,
      'REWARDS-POINTS-REDEEM'
    );
    redemptionDetails.action = '30 Days GoVia Plus subscription activated on your account.';
    redemptionDetails.type = 'SUBSCRIPTION_EXTENDED';

    await PointTransaction.create({
      userId: user._id,
      type: 'REDEEM_SUBSCRIPTION',
      points: -reward.pointsCost,
      balanceAfter: newBalance,
      title: 'Redeemed 30-Day GoVia Plus',
      description: 'Activated 30-day GoVia Plus roadside & safety subscription.',
      metadata: redemptionDetails,
    });
  } else if (reward.actionType === 'GENERATE_GIFT_PASS') {
    // Generate a real GiftCode for Gifting Hub
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    let codePart1 = '';
    let codePart2 = '';
    const bytes = crypto.randomBytes(8);
    for (let i = 0; i < 4; i++) {
      codePart1 += chars[bytes[i] % chars.length];
      codePart2 += chars[bytes[i + 4] % chars.length];
    }
    const giftCode = `GOVIA-GIFT-${codePart1}-${codePart2}`;

    const newGift = await GiftCode.create({
      code: giftCode,
      batchId: crypto.randomUUID(),
      purchasedBy: user._id,
      purchaserName: user.name,
      purchaserRole: USER_ROLES.CITIZEN,
      purchaserEmail: user.email,
      plan: 'PREMIUM_MONTHLY',
      billingCycle: 'MONTHLY',
      durationDays: 30,
      pricePerUnit: 0,
      totalBatchPrice: 0,
      quantity: 1,
      status: 'AVAILABLE',
      expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year expiry
      paymentProvider: 'MANUAL',
      productId: 'govia_gift_referral_points',
    });

    redemptionDetails.giftCode = giftCode;
    redemptionDetails.action = `Gift Pass ${giftCode} generated. Share this code with a friend or family member!`;
    redemptionDetails.type = 'GIFT_PASS_GENERATED';

    await PointTransaction.create({
      userId: user._id,
      type: 'REDEEM_GIFT_PASS',
      points: -reward.pointsCost,
      balanceAfter: newBalance,
      title: 'Redeemed Family Safety Gift Pass',
      description: `Generated 30-Day Safety Pass code: ${giftCode}`,
      metadata: { ...redemptionDetails, giftCodeId: newGift._id },
    });
  } else if (reward.actionType === 'GENERATE_PROVIDER_CREDIT') {
    // Generate $10 Retainer Credit Voucher
    const creditCode = `CREDIT-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
    redemptionDetails.creditCode = creditCode;
    redemptionDetails.creditAmount = 10;
    redemptionDetails.action = `$10 Provider Retainer Voucher generated (${creditCode}).`;
    redemptionDetails.type = 'PROVIDER_CREDIT_GENERATED';

    await PointTransaction.create({
      userId: user._id,
      type: 'REDEEM_PROVIDER_CREDIT',
      points: -reward.pointsCost,
      balanceAfter: newBalance,
      title: 'Redeemed $10 Provider Retainer Credit',
      description: `Generated $10 voucher code: ${creditCode}`,
      metadata: redemptionDetails,
    });
  }

  return {
    success: true,
    message: 'Reward redeemed successfully!',
    details: redemptionDetails,
  };
};

/**
 * Get citizen points transaction history
 */
const getPointTransactions = async (
  userId: string,
  query: Record<string, unknown>
) => {
  const page = Number(query.page) || 1;
  const limit = Math.min(Number(query.limit) || 20, 100);
  const skip = (page - 1) * limit;

  const total = await PointTransaction.countDocuments({ userId });
  const transactions = await PointTransaction.find({ userId })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();

  return {
    meta: {
      page,
      limit,
      total,
      totalPage: Math.ceil(total / limit),
    },
    data: transactions,
  };
};

/**
 * Attribute referral when a new citizen registers
 */
const attributeReferralOnRegister = async (
  newUserId: Types.ObjectId,
  referralCodeInput: string
) => {
  if (!referralCodeInput || !referralCodeInput.trim()) return null;

  const code = referralCodeInput.trim().toUpperCase();

  // Find referrer citizen
  const referrer = await User.findOne({
    referralCode: code,
    role: { $in: [USER_ROLES.CITIZEN, USER_ROLES.USER] },
  });

  if (!referrer || referrer._id.toString() === newUserId.toString()) {
    return null; // Referrer not found or cannot refer self
  }

  // Verify referee hasn't been referred yet
  const existingReferral = await Referral.findOne({ refereeId: newUserId });
  if (existingReferral) return null;

  const referrerAward = REFERRAL_CONSTANTS.POINTS_PER_REFERRAL; // 250
  const refereeAward = REFERRAL_CONSTANTS.WELCOME_BONUS_POINTS; // 100

  // 1. Create Referral record
  const referralRecord = await Referral.create({
    referrerId: referrer._id,
    refereeId: newUserId,
    referralCode: code,
    pointsAwardedToReferrer: referrerAward,
    pointsAwardedToReferee: refereeAward,
    status: 'COMPLETED',
  });

  // 2. Award Referrer (+250)
  const updatedReferrer = await User.findByIdAndUpdate(
    referrer._id,
    {
      $inc: {
        referralPoints: referrerAward,
        lifetimeReferralPoints: referrerAward,
        referralCount: 1,
      },
    },
    { new: true }
  );

  await PointTransaction.create({
    userId: referrer._id,
    type: 'REFERRAL_BONUS',
    points: referrerAward,
    balanceAfter: updatedReferrer?.referralPoints || referrerAward,
    title: 'Friend Joined GoVia!',
    description: `Awarded ${referrerAward} points for referring a fellow citizen.`,
    metadata: { referralId: referralRecord._id, refereeId: newUserId },
  });

  // 3. Award Referee (+100)
  const updatedReferee = await User.findByIdAndUpdate(
    newUserId,
    {
      $set: { referredBy: referrer._id },
      $inc: {
        referralPoints: refereeAward,
        lifetimeReferralPoints: refereeAward,
      },
    },
    { new: true }
  );

  await PointTransaction.create({
    userId: newUserId,
    type: 'WELCOME_BONUS',
    points: refereeAward,
    balanceAfter: updatedReferee?.referralPoints || refereeAward,
    title: 'Welcome Referral Bonus',
    description: `Received ${refereeAward} points for joining via friend invite code ${code}.`,
    metadata: { referralId: referralRecord._id, referrerId: referrer._id },
  });

  // 4. Send in-app notification to referrer
  try {
    await Notification.create({
      userId: referrer._id,
      type: 'system',
      title: '🎉 Referral Bonus Received!',
      subtitle: `A new citizen joined using your code ${code}. +${referrerAward} points added to your balance!`,
      isRead: false,
    });
  } catch (_e) {
    // Non-blocking notification
  }

  return referralRecord;
};

/**
 * Admin overview of platform-wide referral metrics
 */
const getAdminReferralOverview = async () => {
  const totalReferrals = await Referral.countDocuments({ status: 'COMPLETED' });

  // Aggregate points issued
  const pointStats = await PointTransaction.aggregate([
    {
      $group: {
        _id: '$type',
        totalPoints: { $sum: '$points' },
        count: { $sum: 1 },
      },
    },
  ]);

  let totalPointsIssued = 0;
  let totalPointsRedeemed = 0;

  pointStats.forEach(stat => {
    if (stat.totalPoints > 0) {
      totalPointsIssued += stat.totalPoints;
    } else {
      totalPointsRedeemed += Math.abs(stat.totalPoints);
    }
  });

  // Top citizen referrers
  const topReferrers = await User.find({
    role: { $in: [USER_ROLES.CITIZEN, USER_ROLES.USER] },
    referralCount: { $gt: 0 },
  })
    .select('name email image referralCode referralPoints lifetimeReferralPoints referralCount')
    .sort({ referralCount: -1, lifetimeReferralPoints: -1 })
    .limit(10)
    .lean();

  return {
    totalReferrals,
    totalPointsIssued,
    totalPointsRedeemed,
    topReferrers,
    rewardCatalog: REWARD_CATALOG,
  };
};

export const ReferralService = {
  generateUniqueReferralCode,
  getReferralSummary,
  getReferralHistory,
  getRewardsCatalog,
  redeemReward,
  getPointTransactions,
  attributeReferralOnRegister,
  getAdminReferralOverview,
};
