# Citizen Referral Points System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an end-to-end, citizen-exclusive Referral Points & Rewards redemption system across backend APIs, mobile app, and admin dashboard.

**Architecture:** 
- Backend: Extend `User` model with referral code, points balance, and referrer tracking; create `Referral` and `PointTransaction` collections; implement citizen-guarded API endpoints for dashboard stats, referral history, reward redemption, and signup referral attribution.
- Mobile: Restrict the "Referral For Points" entry point strictly to Citizen profiles (remove from Attorney, Bail Bondsman, Doctor, Police profiles); replace hardcoded mock data in `ReferralController` and `ReferralView` with live API data, referral link sharing, and an interactive Rewards Redemption Catalog bottom sheet.
- Admin: Admin view for referral activity, top citizen referrers, total points distributed/redeemed, and configurable points-per-referral rules.

**Tech Stack:** Node.js, Express, TypeScript, Mongoose, Zod, Flutter (GetX, ScreenUtil), Next.js 14, Tailwind CSS.

---

### Task 1: Backend Data Models & Interfaces

**Files:**
- Modify: `apps/backend/src/app/modules/user/user.interface.ts`
- Modify: `apps/backend/src/app/modules/user/user.model.ts`
- Create: `apps/backend/src/app/modules/referral/referral.interface.ts`
- Create: `apps/backend/src/app/modules/referral/referral.model.ts`
- Create: `apps/backend/src/app/modules/referral/pointTransaction.model.ts`

**Details:**
1. Extend `IUser` with:
   - `referralCode?: string;` (unique uppercase alphanumeric code, e.g., `JORDAN77`)
   - `referredBy?: Types.ObjectId | IUser;`
   - `referralPoints: number;` (default 0)
   - `lifetimeReferralPoints: number;` (default 0)
   - `referralCount: number;` (default 0)
2. `IReferral`:
   - `referrerId`: ObjectId (ref: User)
   - `refereeId`: ObjectId (ref: User)
   - `referralCode`: string
   - `pointsAwardedToReferrer`: number (default: 250)
   - `pointsAwardedToReferee`: number (default: 100)
   - `status`: `'COMPLETED' | 'PENDING' | 'REVERTED'`
   - `createdAt`: Date
3. `IPointTransaction`:
   - `userId`: ObjectId (ref: User)
   - `type`: `'REFERRAL_BONUS' | 'WELCOME_BONUS' | 'REDEEM_SUBSCRIPTION' | 'REDEEM_PROVIDER_CREDIT' | 'REDEEM_VAULT_STORAGE' | 'REDEEM_GIFT_PASS' | 'ADMIN_ADJUSTMENT'`
   - `points`: number (positive for credit, negative for debit)
   - `balanceAfter`: number
   - `title`: string
   - `description`: string
   - `metadata`: Record<string, any>
   - `createdAt`: Date

---

### Task 2: Backend Referral Service & Controller Logic

**Files:**
- Create: `apps/backend/src/app/modules/referral/referral.constant.ts`
- Create: `apps/backend/src/app/modules/referral/referral.validation.ts`
- Create: `apps/backend/src/app/modules/referral/referral.service.ts`
- Create: `apps/backend/src/app/modules/referral/referral.controller.ts`
- Create: `apps/backend/src/app/modules/referral/referral.route.ts`
- Modify: `apps/backend/src/app/routes/index.ts`
- Modify: `apps/backend/src/app/modules/user/user.service.ts` (attribution on signup)

**Details:**
1. Endpoints (Strictly for Citizen role):
   - `GET /api/v1/referral/summary`: Returns citizen's referral code, shareable link, point balance, lifetime points, count of successful referrals, and tier.
   - `GET /api/v1/referral/history`: Paginated list of users referred by this citizen with join date and points credited.
   - `GET /api/v1/referral/rewards-catalog`: Available redeemable rewards with required points and details.
   - `POST /api/v1/referral/redeem`: Validates points balance, debits points, creates a `PointTransaction`, and applies reward (e.g. 1 month free citizen subscription, or coupon code).
   - `GET /api/v1/referral/transactions`: Citizen point history (credits and redemptions).
2. Registration Attribution:
   - In `UserService.createUserToDB`, if `payload.referralCode` is provided and new user is `CITIZEN`:
     - Lookup referrer where `referralCode` matches and `role === USER_ROLES.CITIZEN`.
     - Prevent self-referral.
     - Credit 250 points to referrer, 100 welcome bonus to referee.
     - Record `Referral` and both `PointTransaction` documents.
     - Send in-app notification to referrer.

---

### Task 3: Restrict "Referral For Points" Exclusively to Citizens

**Files:**
- Keep in: `apps/mobile/lib/module/citizen/profile/view/citizen_profile_view.dart`
- Remove from: `apps/mobile/lib/module/attorney/profile/view/attorney_profile_view.dart`
- Remove from: `apps/mobile/lib/module/bail_bondsman/profile/view/bail_bondsman_profile_view.dart`
- Remove from: `apps/mobile/lib/module/police/profile/view/police_profile_view.dart`
- Remove from: `apps/mobile/lib/module/doctore/profile/view/doctor_profile_view.dart`

**Details:**
- Delete the `Referral For Points` option item from attorney, bail bondsman, police, and doctor profile screens.
- In `citizen_profile_view.dart`, retain and polish the entry card with active points indicator badge.
- Ensure backend route `/referral/*` enforces `auth(USER_ROLES.CITIZEN)`.

---

### Task 4: Mobile Live Referral Controller & API Integration

**Files:**
- Modify: `apps/mobile/lib/config/constants/api_constants.dart`
- Create: `apps/mobile/lib/data/repositories/referral_repository.dart`
- Modify: `apps/mobile/lib/module/shared/referral/controller/referral_controller.dart`
- Modify: `apps/mobile/lib/module/shared/referral/binding/referral_binding.dart`

**Details:**
1. `ApiConstants`:
   - `referralSummary = '/referral/summary'`
   - `referralHistory = '/referral/history'`
   - `referralRewards = '/referral/rewards-catalog'`
   - `referralRedeem = '/referral/redeem'`
2. `ReferralRepository`:
   - `getSummary()`
   - `getHistory({int page = 1})`
   - `getRewards()`
   - `redeemReward(String rewardId)`
3. `ReferralController`:
   - Reactive variables: `rxPoints`, `rxLifetimePoints`, `rxReferralCount`, `rxReferralCode`, `rxReferralLink`, `isLoading`, `recentReferrals`, `availableRewards`.
   - Methods: `copyReferralLink()`, `shareReferralLink()`, `redeemReward(RewardItem item)`.

---

### Task 5: Mobile UI Polish: Rewards Catalog & Real-Time History

**Files:**
- Modify: `apps/mobile/lib/module/shared/referral/view/referral_view.dart`

**Details:**
1. Points Hero Card:
   - Real-time balance with badge showing Citizen Ambassador Tier (Bronze, Silver, Gold).
   - "Redeem Rewards" button opening the rewards bottom sheet.
2. Share Section:
   - Display Citizen's unique Referral Code chip.
   - Dynamic Referral Link (`https://govia.org/join?ref=<code>`).
   - Quick action buttons: Copy Link, Native Share.
3. Rewards Catalog Bottom Sheet (Grounded in REAL App Systems):
   - **1 Month GoVia Plus Subscription** (1,000 pts): Directly activates/extends the citizen's subscription for 30 days via the existing subscription service.
   - **1-Month Gift Plan Code** (1,000 pts): Generates a real `GOVIA-GIFT-XXXX` code using the existing `giftPlan` engine that the citizen can copy and send to a friend or family member to redeem in their Gifting Hub.
   - **$10 Preferred Provider Retainer Credit** (500 pts): Applied as a discount credit towards the citizen's next preferred attorney or bail bondsman retainer payment.
   - Real-time "Redeem Now" button with balance validation, instant activation, and reward code display.
4. Recent Activity:
   - Real dynamic list loaded from backend. Empty state when no referrals yet.

---

### Task 6: Admin Dashboard: Referral Analytics & Points Settings

**Files:**
- Create/Modify: `apps/admin/src/app/(dashboard)/referrals/page.tsx`
- Modify: `apps/admin/src/components/layout/sidebar.tsx`

**Details:**
- Summary KPIs: Total Referrals Platform-wide, Total Points Issued, Total Points Redeemed, Top Referrer.
- Top Referring Citizens Leaderboard table.
- System Settings card: Configurable points per referral (default 250) and welcome bonus (default 100).

---

### Task 7: End-to-End Verification & Automated Testing

**Details:**
1. Automated Backend Test:
   - Citizen Jordan generates/fetches referral link & code.
   - New citizen registers using Jordan's referral code.
   - Verify Jordan receives +250 points and new citizen receives +100 welcome bonus.
   - Verify Jordan redeems a 500-point reward, points debit to balance, and transaction history updates.
   - Verify provider roles (attorney, doctor) receive HTTP 403 Forbidden if attempting to access citizen referral endpoints.
2. Mobile UI Verification on Android Emulator:
   - Check citizen profile: "Referral For Points" is present.
   - Check attorney and bondsman profiles: "Referral For Points" is removed.
   - Open Referral screen as Citizen Jordan: verify dynamic points balance, referral code, live referral list, and open Rewards Redemption sheet.
