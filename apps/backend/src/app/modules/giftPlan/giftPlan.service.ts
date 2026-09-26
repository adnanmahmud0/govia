import crypto from 'crypto';
import { Types } from 'mongoose';
import { StatusCodes } from 'http-status-codes';
import ApiError from '../../../errors/ApiError';
import { User } from '../user/user.model';
import { GiftCode } from './giftPlan.model';
import {
  IGiftCode,
  IGiftPackageOption,
  IGiftPurchasePayload,
} from './giftPlan.interface';
import { SubscriptionService } from '../subscription/subscription.service';
import { verifyAppleReceipt } from '../subscription/appleIap.service';
import { verifyGooglePlaySubscription } from '../subscription/googlePlay.service';

const GIFT_PACKAGES: IGiftPackageOption[] = [
  {
    id: 'monthly_1',
    productId: 'govia_gift_monthly_1',
    title: 'Individual Gift Pass',
    plan: 'PREMIUM_MONTHLY',
    billingCycle: 'MONTHLY',
    unitsCount: 1,
    durationDays: 30,
    price: 9.99,
    unitPrice: 9.99,
    badge: 'Popular',
    description: '1 Month of unlimited citizen safety and legal protection.',
    features: [
      'Unlimited Emergency Video Calls',
      'Tamper-proof Cloud Video Vault',
      '24/7 Doctor & Mental Health Access',
      'Full GoVia AI Legal Copilot',
    ],
  },
  {
    id: 'yearly_1',
    productId: 'govia_gift_yearly_1',
    title: '1-Year VIP Gift Pass',
    plan: 'PREMIUM_YEARLY',
    billingCycle: 'YEARLY',
    unitsCount: 1,
    durationDays: 365,
    price: 79.99,
    unitPrice: 79.99,
    badge: 'Best Value',
    discountText: 'Save 33%',
    description: 'Full year of comprehensive protection with 2 months free.',
    features: [
      'Everything in Monthly Plan',
      'Full 365 Days Protection',
      'Priority Dispatch to Attorneys',
      'Evidence Export for Legal Counsel',
    ],
  },
  {
    id: 'monthly_3',
    productId: 'govia_gift_monthly_3',
    title: 'Family Pack (3 Gifts)',
    plan: 'PREMIUM_MONTHLY',
    billingCycle: 'MONTHLY',
    unitsCount: 3,
    durationDays: 30,
    price: 26.99,
    unitPrice: 9.0,
    badge: 'Save 10%',
    discountText: '$9.00 / person',
    description: '3 independent 1-Month Gift Passes for family and friends.',
    features: [
      '3 Unique Single-Use Codes',
      'Share via SMS, WhatsApp, or Link',
      'Track Redemptions in Real-time',
    ],
  },
  {
    id: 'monthly_5',
    productId: 'govia_gift_monthly_5',
    title: 'Team Pack (5 Gifts)',
    plan: 'PREMIUM_MONTHLY',
    billingCycle: 'MONTHLY',
    unitsCount: 5,
    durationDays: 30,
    price: 44.99,
    unitPrice: 8.99,
    badge: 'Save 10%',
    discountText: '$8.99 / person',
    description: '5 independent 1-Month Gift Passes for small teams.',
    features: [
      '5 Unique Single-Use Codes',
      'Individual Recipient Tracking',
      'Full Premium Safety Features',
    ],
  },
  {
    id: 'monthly_10',
    productId: 'govia_gift_monthly_10',
    title: 'Community Pack (10 Gifts)',
    plan: 'PREMIUM_MONTHLY',
    billingCycle: 'MONTHLY',
    unitsCount: 10,
    durationDays: 30,
    price: 79.99,
    unitPrice: 7.99,
    badge: 'Save 20%',
    discountText: '$7.99 / person',
    description:
      '10 independent 1-Month Gift Passes for organizations & community groups.',
    features: [
      '10 Unique Single-Use Codes',
      'Max Savings ($20 Off)',
      'Enterprise Gifting Dashboard',
    ],
  },
];

/**
 * Generate a cryptographically secure, readable code
 * Format: GOVIA-GIFT-XXXX-XXXX
 */
const generateUniqueCode = async (): Promise<string> => {
  const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // Exclude ambiguous chars 0, O, 1, I
  let isUnique = false;
  let code = '';

  while (!isUnique) {
    let p1 = '';
    let p2 = '';
    const bytes = crypto.randomBytes(8);
    for (let i = 0; i < 4; i++) {
      p1 += chars[bytes[i] % chars.length];
      p2 += chars[bytes[i + 4] % chars.length];
    }
    code = `GOVIA-GIFT-${p1}-${p2}`;

    const existing = await GiftCode.findOne({ code }).lean();
    if (!existing) {
      isUnique = true;
    }
  }

  return code;
};

/**
 * Retrieve all available gift packages
 */
const getGiftPackages = async (): Promise<IGiftPackageOption[]> => {
  return GIFT_PACKAGES;
};

/**
 * Purchase a gift package and generate single-use codes
 */
const purchaseGiftPackage = async (
  purchaserId: string,
  userRole: string | undefined,
  payload: IGiftPurchasePayload
) => {
  const { productId, provider, purchaseToken, transactionId } = payload;

  const pkg = GIFT_PACKAGES.find(p => p.productId === productId);
  if (!pkg) {
    throw new ApiError(StatusCodes.BAD_REQUEST, `Invalid gift package productId: ${productId}`);
  }

  // Verify IAP receipt if provider is Apple or Google
  if (provider === 'APPLE_IAP' && purchaseToken) {
    const verification = await verifyAppleReceipt(purchaseToken, productId);
    if (!verification.valid) {
      throw new ApiError(
        StatusCodes.PAYMENT_REQUIRED,
        verification.message || 'Apple In-App Purchase verification failed'
      );
    }
  } else if (provider === 'GOOGLE_PLAY' && purchaseToken) {
    const verification = await verifyGooglePlaySubscription(purchaseToken, productId);
    if (!verification.valid) {
      throw new ApiError(
        StatusCodes.PAYMENT_REQUIRED,
        verification.message || 'Google Play In-App Purchase verification failed'
      );
    }
  }

  // Fetch purchaser profile details
  const purchaserDoc = await User.findById(purchaserId).lean();
  if (!purchaserDoc) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Purchaser user account not found');
  }

  const purchaserName = purchaserDoc.name || 'Govia Member';
  const purchaserRole = userRole || purchaserDoc.role || 'CITIZEN';
  const purchaserEmail = purchaserDoc.email || '';

  const batchId = crypto.randomUUID();
  const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year validity to redeem

  const generatedCodes: IGiftCode[] = [];

  for (let i = 0; i < pkg.unitsCount; i++) {
    const code = await generateUniqueCode();
    generatedCodes.push({
      code,
      batchId,
      purchasedBy: new Types.ObjectId(purchaserId),
      purchaserName,
      purchaserRole,
      purchaserEmail,
      plan: pkg.plan,
      billingCycle: pkg.billingCycle,
      durationDays: pkg.durationDays,
      pricePerUnit: pkg.unitPrice,
      totalBatchPrice: pkg.price,
      quantity: pkg.unitsCount,
      status: 'AVAILABLE',
      expiresAt,
      paymentProvider: provider,
      productId: pkg.productId,
      purchaseToken,
      transactionId: transactionId || batchId,
    });
  }

  const inserted = await GiftCode.insertMany(generatedCodes);

  return {
    batchId,
    package: pkg,
    totalCodes: inserted.length,
    codes: inserted.map(c => ({
      id: c._id,
      code: c.code,
      plan: c.plan,
      durationDays: c.durationDays,
      status: c.status,
      expiresAt: c.expiresAt,
      createdAt: c.createdAt,
    })),
  };
};

/**
 * Retrieve all gift codes purchased by the authenticated user
 * (Includes recipient tracking: who used the code, when)
 */
const getMyPurchasedGifts = async (purchaserId: string) => {
  const codes = await GiftCode.find({
    purchasedBy: new Types.ObjectId(purchaserId),
  })
    .sort({ createdAt: -1 })
    .lean();

  const totalPurchased = codes.length;
  const totalRedeemed = codes.filter(c => c.status === 'REDEEMED').length;
  const totalAvailable = codes.filter(c => c.status === 'AVAILABLE').length;

  return {
    summary: {
      totalPurchased,
      totalRedeemed,
      totalAvailable,
    },
    codes: codes.map(c => ({
      id: c._id,
      code: c.code,
      batchId: c.batchId,
      plan: c.plan,
      billingCycle: c.billingCycle,
      durationDays: c.durationDays,
      pricePerUnit: c.pricePerUnit,
      status: c.status,
      isRedeemed: c.status === 'REDEEMED',
      redeemedByName: c.redeemedByName || null,
      redeemedByEmail: c.redeemedByEmail || null,
      redeemedByAvatar: c.redeemedByAvatar || null,
      redeemedAt: c.redeemedAt || null,
      expiresAt: c.expiresAt,
      createdAt: c.createdAt,
    })),
  };
};

/**
 * Validate a gift code and preview subscription details
 */
const validateGiftCode = async (code: string) => {
  const cleanCode = code.trim().toUpperCase();
  const giftDoc = await GiftCode.findOne({ code: cleanCode }).lean();

  if (!giftDoc) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Invalid gift code. Please check and try again.');
  }

  if (giftDoc.status === 'REDEEMED') {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      `This gift code was already redeemed on ${giftDoc.redeemedAt ? new Date(giftDoc.redeemedAt).toLocaleDateString() : 'a previous date'}.`
    );
  }

  if (giftDoc.status === 'EXPIRED' || giftDoc.expiresAt < new Date()) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'This gift code has expired.');
  }

  return {
    valid: true,
    code: giftDoc.code,
    plan: giftDoc.plan,
    durationDays: giftDoc.durationDays,
    purchaserName: giftDoc.purchaserName,
    purchaserRole: giftDoc.purchaserRole,
    expiresAt: giftDoc.expiresAt,
    features: [
      'Unlimited Emergency Video Calls (24/7)',
      'Tamper-proof Cloud Video Vault & Playback',
      'Direct Confidential Doctor & Mental Health Access',
      'Advanced GoVia AI Legal Assistant',
    ],
  };
};

/**
 * Redeem a gift code atomically (single-use lock) and activate subscription
 */
const redeemGiftCode = async (
  recipientUserId: string,
  userRole: string | undefined,
  code: string
) => {
  const cleanCode = code.trim().toUpperCase();
  const now = new Date();

  // Fetch recipient user details
  const recipientDoc = await User.findById(recipientUserId).lean();
  if (!recipientDoc) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Recipient user account not found');
  }

  const recipientName = recipientDoc.name || 'Govia Citizen';
  const recipientEmail = recipientDoc.email || '';
  const recipientAvatar =
    (recipientDoc as any).image || (recipientDoc as any).profilePicture || '';

  // Atomic find and update: ONLY succeed if code is AVAILABLE and not expired
  const updatedCode = await GiftCode.findOneAndUpdate(
    {
      code: cleanCode,
      status: 'AVAILABLE',
      expiresAt: { $gt: now },
    },
    {
      $set: {
        status: 'REDEEMED',
        redeemedBy: new Types.ObjectId(recipientUserId),
        redeemedByName: recipientName,
        redeemedByEmail: recipientEmail,
        redeemedByAvatar: recipientAvatar,
        redeemedAt: now,
      },
    },
    { new: true }
  );

  if (!updatedCode) {
    // Determine the exact reason for failure to provide clear user feedback
    const existing = await GiftCode.findOne({ code: cleanCode }).lean();
    if (!existing) {
      throw new ApiError(StatusCodes.NOT_FOUND, 'Invalid gift code. Please check and try again.');
    }
    if (existing.status === 'REDEEMED') {
      throw new ApiError(
        StatusCodes.BAD_REQUEST,
        'This gift code has already been redeemed and can only be used once.'
      );
    }
    if (existing.expiresAt <= now) {
      throw new ApiError(StatusCodes.BAD_REQUEST, 'This gift code has expired.');
    }
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Unable to redeem this gift code.');
  }

  // Activate or extend subscription in SubscriptionService
  const subscription = await SubscriptionService.activateGiftSubscription(
    recipientUserId,
    userRole,
    updatedCode.plan,
    updatedCode.durationDays,
    updatedCode.code
  );

  return {
    success: true,
    message: `Gift code successfully redeemed! Your account is now active with ${updatedCode.plan === 'PREMIUM_YEARLY' ? '1 Year' : '1 Month'} Govia Premium.`,
    code: updatedCode.code,
    plan: updatedCode.plan,
    durationDays: updatedCode.durationDays,
    giverName: updatedCode.purchaserName,
    giverRole: updatedCode.purchaserRole,
    subscription: {
      id: subscription._id,
      status: subscription.status,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
    },
  };
};

export const GiftPlanService = {
  getGiftPackages,
  purchaseGiftPackage,
  getMyPurchasedGifts,
  validateGiftCode,
  redeemGiftCode,
};
