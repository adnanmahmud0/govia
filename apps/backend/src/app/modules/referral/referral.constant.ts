import { IRewardCatalogItem } from './referral.interface';

export const REFERRAL_CONSTANTS = {
  POINTS_PER_REFERRAL: 250,
  WELCOME_BONUS_POINTS: 100,
  BASE_WEB_URL: 'https://govia.org/join',
};

export const REWARD_CATALOG: IRewardCatalogItem[] = [
  {
    id: 'reward_plus_month',
    title: '1-Month GoVia Plus Extension',
    description: 'Instantly add 30 days of GoVia Plus roadside incident and safety coverage to your citizen account.',
    pointsCost: 1000,
    category: 'SUBSCRIPTION',
    badge: 'Most Popular',
    isPopular: true,
    actionType: 'ACTIVATE_SUBSCRIPTION',
  },
  {
    id: 'reward_gift_pass',
    title: '30-Day Family Safety Gift Pass',
    description: 'Generate an exclusive GOVIA-GIFT code to share 1 full month of GoVia safety protection with a loved one.',
    pointsCost: 1000,
    category: 'GIFT',
    badge: 'Shareable Gift',
    isPopular: false,
    actionType: 'GENERATE_GIFT_PASS',
  },
  {
    id: 'reward_provider_credit',
    title: '$10 Preferred Provider Retainer Credit',
    description: 'Redeem an instant $10 discount voucher towards your next retainer payment to a preferred attorney or bail bondsman.',
    pointsCost: 500,
    category: 'CREDIT',
    badge: 'Instant Savings',
    isPopular: false,
    actionType: 'GENERATE_PROVIDER_CREDIT',
  },
];
