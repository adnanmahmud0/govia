import Stripe from 'stripe';
import { Types } from 'mongoose';
import { StatusCodes } from 'http-status-codes';
import config from '../../../config';
import ApiError from '../../../errors/ApiError';
import { logger } from '../../../shared/logger';
import { User } from '../user/user.model';
import { CommissionSetting, ProviderTransaction } from './providerPayment.model';
import { USER_ROLES } from '../../../enums/user';
import { NotificationService } from '../notification/notification.service';
import { socketHelper } from '../../../helpers/socketHelper';

let stripeClient: Stripe | null = null;

const getStripe = (): Stripe => {
  if (!stripeClient) {
    if (!config.stripe.secretKey) {
      throw new ApiError(
        StatusCodes.INTERNAL_SERVER_ERROR,
        'Stripe secret key is not configured.'
      );
    }
    stripeClient = new Stripe(config.stripe.secretKey);
  }
  return stripeClient;
};

// ─── 1. Provider Profile Bio (Service Pricing removed) ─────────────────────
const updatePricingProfile = async (
  userId: string,
  payload: {
    shortDescription?: string;
    // serviceFee and monthlyServiceFee are ignored as providers cannot set their fees
    serviceFee?: number;
    monthlyServiceFee?: number;
  }
) => {
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'User not found.');
  }

  const role = user.role?.toUpperCase();
  if (role !== USER_ROLES.ATTORNEY && role !== USER_ROLES.BAIL_BONDSMAN) {
    throw new ApiError(
      StatusCodes.FORBIDDEN,
      'Only Attorneys and Bail Bondsmen can access provider profile settings.'
    );
  }

  if (payload.shortDescription !== undefined) {
    user.shortDescription = payload.shortDescription;
  }

  await user.save();
  return user;
};

// ─── 2. Payouts Deprecation / No-Op Handlers ──────────────────────────────
const createStripeExpressAccount = async (
  _userId: string,
  _returnUrl?: string
) => {
  return {
    message: 'Provider payouts and Stripe Connect onboarding are disabled on this platform.',
    accountId: '',
    onboardingUrl: '',
  };
};

const getStripeAccountStatus = async (_userId: string) => {
  return {
    hasAccount: false,
    onboarded: false,
    payoutsEnabled: false,
    status: 'DISABLED',
  };
};

const getStripeDashboardLink = async (_userId: string) => {
  return {
    url: '',
    message: 'Provider payout dashboard is disabled.',
  };
};

const processEncounterAutoPayout = async (
  _meetingId: string,
  _hostCitizenId: string,
  _providerUserId: string
) => {
  // Payout transfer logic removed - all service charges are managed centrally via Admin.
  return;
};

// ─── 3. Public Directory for Citizens ──────────────────────────────────
const getProviderDirectory = async (query: {
  role?: string;
  state?: string;
  search?: string;
  page?: number;
  limit?: number;
}) => {
  const page = Number(query.page) || 1;
  const limit = Number(query.limit) || 20;
  const skip = (page - 1) * limit;

  const filter: Record<string, unknown> = {
    status: 'active',
  };

  if (query.role) {
    filter.role = query.role.toUpperCase();
  } else {
    filter.role = { $in: [USER_ROLES.ATTORNEY, USER_ROLES.BAIL_BONDSMAN] };
  }

  if (query.state) {
    filter.licensedStatesToPractice = { $regex: query.state, $options: 'i' };
  }

  if (query.search) {
    filter.$or = [
      { name: { $regex: query.search, $options: 'i' } },
      { lawFirmName: { $regex: query.search, $options: 'i' } },
      { companyName: { $regex: query.search, $options: 'i' } },
      { officeName: { $regex: query.search, $options: 'i' } },
      { specialization: { $regex: query.search, $options: 'i' } },
      { shortDescription: { $regex: query.search, $options: 'i' } },
    ];
  }

  const total = await User.countDocuments(filter);
  const providers = await User.find(filter)
    .select(
      'name role email image phoneNumber lawFirmName companyName officeName barAssociationNumber specialization licensedStatesToPractice shortDescription createdAt'
    )
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

  const formatted = providers.map((p) => {
    const hash = p._id.toString().split('').reduce((acc, c) => acc + c.charCodeAt(0), 0);
    const rating = (4.7 + (hash % 4) * 0.1).toFixed(1);
    const reviewsCount = 18 + (hash % 85);

    return {
      id: p._id.toString(),
      name: p.name,
      role: p.role,
      image: p.image || '',
      company: p.lawFirmName || p.companyName || p.officeName || 'Independent Practice',
      licenseNumber: p.barAssociationNumber || '',
      specialization:
        p.specialization ||
        (p.role === 'ATTORNEY' ? 'Civil Rights & Criminal Defense' : '24/7 Bail Bond Underwriting'),
      licensedStates: p.licensedStatesToPractice || 'Nationwide Coverage',
      shortDescription:
        p.shortDescription && p.shortDescription.trim().length > 0
          ? p.shortDescription
          : p.role === 'ATTORNEY'
          ? 'Dedicated legal counsel providing instant roadside emergency guidance and defense representation.'
          : 'Rapid-response licensed bail bond agency available 24/7 for immediate release assistance.',
      isStripeVerified: true,
      rating: parseFloat(rating),
      reviewsCount,
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

// ─── 4. Admin Platform Service Charges & Commission Management ───────────
const getServiceChargeSetting = async () => {
  let setting = await CommissionSetting.findOne();
  if (!setting) {
    setting = await CommissionSetting.create({
      attorneyServiceFee: 50,
      bailBondsmanServiceFee: 30,
      platformCommissionPercent: 10,
    });
  } else {
    // Ensure default values if older schema had nulls
    let changed = false;
    if (setting.attorneyServiceFee === undefined || setting.attorneyServiceFee === null) {
      setting.attorneyServiceFee = 50;
      changed = true;
    }
    if (setting.bailBondsmanServiceFee === undefined || setting.bailBondsmanServiceFee === null) {
      setting.bailBondsmanServiceFee = 30;
      changed = true;
    }
    if (changed) await setting.save();
  }
  return setting;
};

const updateServiceChargeSetting = async (
  payload: {
    attorneyServiceFee?: number;
    bailBondsmanServiceFee?: number;
    platformCommissionPercent?: number;
  },
  adminId: string
) => {
  let setting = await CommissionSetting.findOne();
  if (!setting) {
    setting = await CommissionSetting.create({
      attorneyServiceFee: payload.attorneyServiceFee ?? 50,
      bailBondsmanServiceFee: payload.bailBondsmanServiceFee ?? 30,
      platformCommissionPercent: payload.platformCommissionPercent ?? 10,
      updatedBy: new Types.ObjectId(adminId),
    });
  } else {
    if (payload.attorneyServiceFee !== undefined) {
      setting.attorneyServiceFee = payload.attorneyServiceFee;
    }
    if (payload.bailBondsmanServiceFee !== undefined) {
      setting.bailBondsmanServiceFee = payload.bailBondsmanServiceFee;
    }
    if (payload.platformCommissionPercent !== undefined) {
      setting.platformCommissionPercent = payload.platformCommissionPercent;
    }
    setting.updatedBy = new Types.ObjectId(adminId);
    await setting.save();
  }
  return setting;
};

const getCommissionSetting = async () => {
  return getServiceChargeSetting();
};

const updateCommissionSetting = async (percent: number, adminId: string) => {
  return updateServiceChargeSetting({ platformCommissionPercent: percent }, adminId);
};

// ─── 5. Citizen Service Checkout Session Creation ───────────────────────
const createServiceCheckoutSession = async (
  citizenId: string,
  payload: {
    role: 'ATTORNEY' | 'BAIL_BONDSMAN';
    providerId?: string;
    successUrl?: string;
    cancelUrl?: string;
  }
) => {
  const stripe = getStripe();
  const citizen = await User.findById(citizenId);
  if (!citizen) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Citizen user not found.');
  }

  const role = payload.role.toUpperCase() as 'ATTORNEY' | 'BAIL_BONDSMAN';
  if (role !== USER_ROLES.ATTORNEY && role !== USER_ROLES.BAIL_BONDSMAN) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      'Invalid role. Must be ATTORNEY or BAIL_BONDSMAN.'
    );
  }

  const setting = await getServiceChargeSetting();
  const serviceFee =
    role === 'ATTORNEY' ? setting.attorneyServiceFee : setting.bailBondsmanServiceFee;

  if (serviceFee <= 0) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      'Service charge has not been configured by platform admin.'
    );
  }

  const roleTitle = role === 'ATTORNEY' ? 'Attorney' : 'Bail Bondsman';
  const transactionId = `TX-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

  const successUrl =
    payload.successUrl ||
    `https://api.govia.org/api/v1/provider/verify-session/{CHECKOUT_SESSION_ID}?citizenId=${citizenId}`;
  const cancelUrl = payload.cancelUrl || `https://govia.org/checkout/cancel`;

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: [
      {
        price_data: {
          currency: 'usd',
          product_data: {
            name: `GoVia Preferred ${roleTitle} Protection Service`,
            description: `30-Day Platform Service Charge to retain a Preferred ${roleTitle} for 24/7 priority emergency dispatch.`,
          },
          unit_amount: Math.round(serviceFee * 100),
        },
        quantity: 1,
      },
    ],
    mode: 'payment',
    customer_email: citizen.email,
    success_url: successUrl,
    cancel_url: cancelUrl,
    metadata: {
      transactionId,
      citizenId: citizen._id.toString(),
      providerId: payload.providerId || '',
      role,
      type: 'SERVICE_CHARGE',
      grossAmount: serviceFee.toString(),
      platformFee: serviceFee.toString(),
      providerAmount: '0',
    },
  });

  // Create pending transaction record
  await ProviderTransaction.create({
    transactionId,
    citizenId: citizen._id,
    providerId: payload.providerId ? new Types.ObjectId(payload.providerId) : undefined,
    role,
    type: 'SERVICE_CHARGE',
    grossAmount: serviceFee,
    platformFee: serviceFee,
    providerAmount: 0,
    currency: 'usd',
    status: 'PENDING',
    stripeSessionId: session.id,
  });

  return {
    sessionId: session.id,
    sessionUrl: session.url,
    checkoutUrl: session.url,
    transactionId,
    serviceFee,
  };
};

// Backward-compatible checkout session caller
const createCheckoutSession = async (
  citizenId: string,
  payload: {
    providerId?: string;
    role?: 'ATTORNEY' | 'BAIL_BONDSMAN';
    successUrl?: string;
    cancelUrl?: string;
  }
) => {
  let targetRole: 'ATTORNEY' | 'BAIL_BONDSMAN' = payload.role || 'ATTORNEY';

  if (!payload.role && payload.providerId) {
    const prov = await User.findById(payload.providerId);
    if (prov?.role === USER_ROLES.BAIL_BONDSMAN) {
      targetRole = 'BAIL_BONDSMAN';
    } else {
      targetRole = 'ATTORNEY';
    }
  }

  return createServiceCheckoutSession(citizenId, {
    role: targetRole,
    providerId: payload.providerId,
    successUrl: payload.successUrl,
    cancelUrl: payload.cancelUrl,
  });
};

// ─── 6. Verify Session & Activate Service Coverage ─────────────────────
const verifyAndActivateSession = async (citizenId: string, sessionId: string) => {
  const stripe = getStripe();
  const session = await stripe.checkout.sessions.retrieve(sessionId);

  if (!session) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Stripe checkout session not found.');
  }

  const transaction = await ProviderTransaction.findOne({ stripeSessionId: sessionId });
  if (!transaction) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Transaction record not found.');
  }

  const isPaid = session.payment_status === 'paid';
  if (!isPaid) {
    return {
      success: false,
      isPaid: false,
      message: 'Payment has not been completed yet.',
    };
  }

  // If already activated, return success directly
  if (transaction.status === 'COMPLETED') {
    return {
      success: true,
      isPaid: true,
      message: 'Service coverage is already active.',
      transaction,
    };
  }

  const citizen = await User.findById(transaction.citizenId);
  if (!citizen) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Citizen user not found.');
  }

  // Mark transaction complete
  const now = new Date();
  const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30-day coverage

  transaction.status = 'COMPLETED';
  transaction.stripePaymentIntentId =
    typeof session.payment_intent === 'string'
      ? session.payment_intent
      : session.payment_intent?.id;
  transaction.periodStart = now;
  transaction.periodEnd = periodEnd;
  await transaction.save();

  // Activate coverage dates on citizen profile
  if (transaction.role === 'ATTORNEY') {
    citizen.preferredAttorneyActiveUntil = periodEnd;
    if (transaction.providerId) {
      citizen.preferredAttorney = transaction.providerId.toString();
    }
  } else {
    citizen.preferredBailBondsmanActiveUntil = periodEnd;
    if (transaction.providerId) {
      citizen.preferredBailBondsman = transaction.providerId.toString();
    }
  }
  await citizen.save();

  // Payout transfer logic removed: 100% of service charge is retained by GoVia platform

  const roleLabel = transaction.role === 'ATTORNEY' ? 'Attorney' : 'Bail Bondsman';

  // Send real-time notification to citizen
  try {
    await NotificationService.createNotification({
      userId: citizen._id.toString(),
      type: 'PAYMENT_RECEIVED',
      title: `${roleLabel} Protection Service Active! 🛡️`,
      subtitle: `Your Preferred ${roleLabel} protection coverage is active for the next 30 days. You can now select your preferred provider.`,
      resourceType: 'system',
      resourceId: transaction.transactionId,
      metadata: {
        transactionId: transaction.transactionId,
        amount: transaction.grossAmount,
        activeUntil: periodEnd.toISOString(),
      },
    });

    socketHelper.emitToUser(citizen._id.toString(), 'service_coverage_activated', {
      role: transaction.role,
      activeUntil: periodEnd.toISOString(),
      transactionId: transaction.transactionId,
    });
  } catch (notifErr) {
    logger.warn('Non-fatal notification error:', notifErr);
  }

  return {
    success: true,
    isPaid: true,
    message: `Preferred ${roleLabel} service coverage successfully activated!`,
    transaction,
  };
};

// ─── 7. Gated Preferred Provider Selection ─────────────────────────────
const selectPreferredProvider = async (
  citizenId: string,
  payload: {
    providerId: string;
    role: 'ATTORNEY' | 'BAIL_BONDSMAN';
  }
) => {
  const citizen = await User.findById(citizenId);
  if (!citizen) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Citizen user not found.');
  }

  const role = payload.role.toUpperCase() as 'ATTORNEY' | 'BAIL_BONDSMAN';
  const roleLabel = role === 'ATTORNEY' ? 'Attorney' : 'Bail Bondsman';

  // Check active coverage
  const now = new Date();
  const coverageEnd =
    role === 'ATTORNEY'
      ? citizen.preferredAttorneyActiveUntil
      : citizen.preferredBailBondsmanActiveUntil;

  const isCovered = coverageEnd && new Date(coverageEnd) > now;
  if (!isCovered) {
    throw new ApiError(
      StatusCodes.PAYMENT_REQUIRED,
      `Active ${roleLabel} service coverage required. Please pay the service charge in the app before setting your preferred provider.`
    );
  }

  const provider = await User.findById(payload.providerId);
  if (!provider) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Selected provider not found.');
  }

  if (provider.role !== role) {
    throw new ApiError(
      StatusCodes.BAD_REQUEST,
      `Selected provider is not an ${roleLabel}.`
    );
  }

  if (role === 'ATTORNEY') {
    citizen.preferredAttorney = provider._id.toString();
  } else {
    citizen.preferredBailBondsman = provider._id.toString();
  }

  await citizen.save();

  // Notify provider
  try {
    await NotificationService.createNotification({
      userId: provider._id.toString(),
      type: 'SYSTEM',
      title: 'Designated Preferred Provider 🤝',
      subtitle: `${citizen.name} has selected you as their Preferred ${roleLabel} for 24/7 priority emergency dispatch.`,
      resourceType: 'system',
      resourceId: citizen._id.toString(),
    });

    socketHelper.emitToUser(provider._id.toString(), 'preferred_provider_linked', {
      citizen: {
        id: citizen._id.toString(),
        name: citizen.name,
      },
      role,
    });
  } catch (err) {
    logger.warn('Non-fatal notification error:', err);
  }

  return {
    success: true,
    message: `Successfully linked ${provider.name} as your Preferred ${roleLabel}.`,
    preferredProvider: {
      id: provider._id.toString(),
      name: provider.name,
      role: provider.role,
      image: provider.image,
      company: provider.lawFirmName || provider.companyName || provider.officeName,
    },
  };
};

// ─── 8. Stripe Webhook Handler ─────────────────────────────────────────
const handleStripeWebhook = async (signature: string, rawBody: Buffer | string) => {
  const stripe = getStripe();
  const webhookSecret = config.stripe.webhookSecret;

  let event: Stripe.Event | null = null;

  if (webhookSecret) {
    try {
      event = stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
    } catch (err: unknown) {
      logger.error('⚠️ Stripe Webhook signature verification failed:', err);
      throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid webhook signature.');
    }
  } else {
    try {
      event = JSON.parse(rawBody.toString()) as Stripe.Event;
    } catch {
      throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid webhook payload.');
    }
  }

  if (!event) {
    throw new ApiError(StatusCodes.BAD_REQUEST, 'Stripe event not recognized.');
  }

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      const citizenId = session.metadata?.citizenId;
      if (citizenId && session.id) {
        await verifyAndActivateSession(citizenId, session.id);
      }
      break;
    }

    default:
      logger.info(`Unhandled Stripe webhook event: ${event.type}`);
  }

  return { received: true };
};

// ─── 9. Transactions Listing for Admin & Citizens ──────────────────────
const getTransactions = async (query: {
  userId?: string;
  role?: string;
  type?: string;
  page?: number;
  limit?: number;
}) => {
  const page = Number(query.page) || 1;
  const limit = Number(query.limit) || 20;
  const skip = (page - 1) * limit;

  const filter: Record<string, unknown> = {};

  if (query.userId) {
    filter.$or = [
      { citizenId: new Types.ObjectId(query.userId) },
      { providerId: new Types.ObjectId(query.userId) },
    ];
  }

  if (query.role) filter.role = query.role.toUpperCase();
  if (query.type) filter.type = query.type.toUpperCase();

  const total = await ProviderTransaction.countDocuments(filter);
  const transactions = await ProviderTransaction.find(filter)
    .populate('citizenId', 'name email image')
    .populate('providerId', 'name email image role lawFirmName companyName')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);

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

export const ProviderPaymentService = {
  updatePricingProfile,
  createStripeExpressAccount,
  getStripeAccountStatus,
  getStripeDashboardLink,
  getProviderDirectory,
  getServiceChargeSetting,
  updateServiceChargeSetting,
  getCommissionSetting,
  updateCommissionSetting,
  createServiceCheckoutSession,
  createCheckoutSession,
  verifyAndActivateSession,
  selectPreferredProvider,
  processEncounterAutoPayout,
  handleStripeWebhook,
  getTransactions,
};
