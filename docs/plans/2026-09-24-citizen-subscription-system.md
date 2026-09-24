# Citizen Tiered Subscription System (Google Play & Apple IAP) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a robust, end-to-end monetization and feature-gating system strictly targeting the **Citizen role** (`CITIZEN` / `USER`), with Google Play & Apple App Store in-app purchases (IAP), monthly meeting quotas (3/month for Free), OpenRouter free model rotation, recording playback restrictions, doctor communication locks, and a sleek, high-converting mobile paywall UI.

**Architecture:** 
- **Role Isolation:** Only `CITIZEN` and `USER` roles are subject to the subscription requirement and limits. Professional roles (`ATTORNEY`, `POLICE`, `BAIL_BONDSMAN`, `MENTAL_HEALTH_PROFESSIONAL`, `ADMIN`, `SUPER_ADMIN`) bypass all citizen gates automatically.
- **Backend Subscription Module:** Express.js `Subscription` & `CitizenUsage` collections, plus native receipt verification services for **Apple App Store** (`verifyReceipt` / StoreKit) and **Google Play Developer API** (purchases.subscriptions). Gracefully handles sandbox and pending credentials with automated fallback.
- **Feature Gating Engine:** Intercepts `start-govia`/`emergency-call` (3/month quota for Free), `aiAssistant` (dynamic OpenRouter free model pool rotation), `recordingUrl` exposure/playback, and doctor communication (chat/appointments).
- **Mobile Paywall Redesign (`apps/mobile`):** Flutter GetX UI with fluid Monthly/Yearly toggle switch, "SAVE 33%" discount badge, comparative feature matrix, Google Play & Apple In-App Purchase integration (`in_app_purchase`), and proactive upgrade modals at restricted feature touchpoints.

**Tech Stack:** Node.js, Express, TypeScript, Mongoose/MongoDB, OpenRouter AI, Google Play Billing API, Apple StoreKit Verification, Flutter 3.x, Dart, GetX, in_app_purchase.

---

## Detailed Implementation Tasks

### Task 1: Environment Variables & Verification Configuration
**Files:**
- Modify: `.env`
- Modify: `.env.example`
- Modify: `apps/backend/src/config/index.ts`

**Changes:**
Add configuration section for Apple & Google IAP credentials:
```env
# In-App Purchases (Apple App Store & Google Play)
APPLE_BUNDLE_ID=com.govia.app
APPLE_SHARED_SECRET=
APPLE_ENVIRONMENT=sandbox
GOOGLE_PACKAGE_NAME=com.govia.app
GOOGLE_SERVICE_ACCOUNT_EMAIL=
GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY=
```
In `apps/backend/src/config/index.ts`, add `iap` object with `apple` and `google` settings.

---

### Task 2: Backend Models & Schema
**Files:**
- Create: `apps/backend/src/app/modules/subscription/subscription.interface.ts`
- Create: `apps/backend/src/app/modules/subscription/subscription.model.ts`
- Create: `apps/backend/src/app/modules/subscription/citizenUsage.model.ts`

**Details:**
- `ISubscription`:
  - `userId`: ObjectId ref User
  - `role`: string (defaults to `CITIZEN`)
  - `plan`: `'FREE' | 'PREMIUM_MONTHLY' | 'PREMIUM_YEARLY'`
  - `status`: `'ACTIVE' | 'EXPIRED' | 'CANCELLED'`
  - `billingCycle`: `'MONTHLY' | 'YEARLY' | 'NONE'`
  - `price`: number ($0, $9.99, $79.99)
  - `currency`: `'USD'`
  - `startDate`: Date
  - `endDate`: Date
  - `autoRenew`: boolean
  - `paymentProvider`: `'APPLE_IAP' | 'GOOGLE_PLAY' | 'STRIPE' | 'MANUAL'`
  - `receiptToken`: string (Google purchaseToken or Apple receipt-data)
  - `productId`: string (`govia_premium_monthly` or `govia_premium_yearly`)
  - `transactionId`: string
- `ICitizenUsage`:
  - `userId`: ObjectId ref User
  - `yearMonth`: string (e.g. `'2026-09'`)
  - `meetingCount`: number
  - `lastMeetingAt`: Date
  - Compound unique index on `{ userId: 1, yearMonth: 1 }`

---

### Task 3: Apple StoreKit & Google Play Backend Verifier
**Files:**
- Create: `apps/backend/src/app/modules/subscription/appleIap.service.ts`
- Create: `apps/backend/src/app/modules/subscription/googlePlay.service.ts`

**Details:**
- `verifyAppleReceipt(receiptData: string, productId: string)`:
  - If `APPLE_SHARED_SECRET` is configured, verifies with Apple Sandbox/Production API.
  - If credentials are not yet added in `.env`, verifies receipt structure, decodes payload, and allows development/sandbox activation so development never halts.
- `verifyGooglePurchase(purchaseToken: string, subscriptionId: string)`:
  - If `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY` is configured, verifies token via Google Play Developer API.
  - If credentials are not yet added, validates token format and approves mock/sandbox test purchases seamlessly.

---

### Task 4: Backend Subscription Service, Controller & Routes
**Files:**
- Create: `apps/backend/src/app/modules/subscription/subscription.service.ts`
- Create: `apps/backend/src/app/modules/subscription/subscription.controller.ts`
- Create: `apps/backend/src/app/modules/subscription/subscription.validation.ts`
- Create: `apps/backend/src/app/modules/subscription/subscription.route.ts`
- Modify: `apps/backend/src/app/routes/index.ts`

**Key Business Rules:**
- `getUserSubscriptionStatus(user)`:
  - If `user.role !== USER_ROLES.CITIZEN && user.role !== USER_ROLES.USER`:
    - Returns `{ role: user.role, plan: 'EXEMPT', isCitizen: false, needsSubscription: false, canStartUnlimitedMeetings: true, canViewRecordings: true, hasDoctorSupport: true, hasPremiumAI: true }`.
  - If `user.role === USER_ROLES.CITIZEN || user.role === USER_ROLES.USER`:
    - Checks active subscription. If none or expired, defaults to `FREE`.
    - Queries `CitizenUsage` for current `YYYY-MM`.
    - Returns `{ role: 'CITIZEN', plan: 'FREE' | 'PREMIUM_MONTHLY' | 'PREMIUM_YEARLY', isCitizen: true, needsSubscription: true, monthlyUsage: { used: count, limit: 3, remaining: Math.max(0, 3 - count) }, features: { unlimitedMeetings, viewRecordings, doctorSupport, premiumAI } }`.
- `verifyAndSubscribeIAP(userId, userRole, provider, productId, token)`:
  - Validates role is Citizen.
  - Calls Apple/Google verifier.
  - Activates subscription for 1 month or 1 year.
- `subscribeManual(userId, plan, billingCycle)`:
  - For quick testing and direct upgrades.
- Register routes:
  - `GET /api/v1/subscriptions/my-status`
  - `GET /api/v1/subscriptions/plans`
  - `POST /api/v1/subscriptions/verify-iap`
  - `POST /api/v1/subscriptions/subscribe`
  - `POST /api/v1/subscriptions/cancel`

---

### Task 5: Backend Meeting Quota Guard (3 Free Meetings / Month strictly for Citizens)
**Files:**
- Modify: `apps/backend/src/app/modules/meeting/meeting.service.ts`

**Details:**
- In `createInstantMeeting`:
  - Check host user role:
    - If `user.role !== USER_ROLES.CITIZEN && user.role !== USER_ROLES.USER`:
      - **Bypass quota entirely.** (Attorneys, police, bondsmen, admins are exempt).
    - If `user.role === USER_ROLES.CITIZEN || user.role === USER_ROLES.USER`:
      - Check subscription tier.
      - If `FREE`:
        - Query monthly count.
        - If `count >= 3`, throw `ApiError(StatusCodes.FORBIDDEN, 'You have reached your limit of 3 free emergency/Govia meetings this month. Upgrade to Premium for unlimited emergency protection.')` with error code `SUBSCRIPTION_LIMIT_EXCEEDED`.
        - Else: increment monthly usage counter.
      - If `PREMIUM_MONTHLY` or `PREMIUM_YEARLY`:
        - Allow unlimited meetings.

---

### Task 6: Backend AI Assistant Model Pool (OpenRouter Free Model Pool vs Premium)
**Files:**
- Modify: `apps/backend/src/app/modules/aiAssistant/aiAssistant.service.ts`

**Details:**
- Define pool of reliable free OpenRouter models:
  ```ts
  const FREE_OPENROUTER_MODELS = [
    'meta-llama/llama-3.3-70b-instruct:free',
    'google/gemini-2.0-flash-exp:free',
    'deepseek/deepseek-r1:free',
    'qwen/qwen-2.5-coder-32b-instruct:free',
    'mistralai/mistral-small-24b-instruct-2501:free',
    'openrouter/free'
  ];
  ```
- In `generateResponse`:
  - Check user role and tier.
  - If non-citizen or citizen on `PREMIUM`: use configured top-tier model (`config.ai.modelName` or `'openai/gpt-4o'`).
  - If Free Citizen: randomly select one model from `FREE_OPENROUTER_MODELS` with retry fallback.

---

### Task 7: Backend Recording Access Guard (Hidden for Free Citizens)
**Files:**
- Modify: `apps/backend/src/app/modules/meeting/meeting.service.ts`
- Modify: `apps/backend/src/app/modules/meeting/meeting.controller.ts`

**Details:**
- In `getMyMeetings`:
  - For Free Citizens: set `recordingUrl = null` and `isRecordingLocked: true`.
  - For Premium Citizens and all Professional Roles: return full recording URL and `isRecordingLocked: false`.
- In `getRecordings`:
  - If requester is a Free Citizen, reject with 403: *"Session recordings are only available on Govia Premium."*

---

### Task 8: Backend Doctor & Mental Health Consultation Guard
**Files:**
- Modify: `apps/backend/src/app/modules/conversation/conversation.service.ts`
- Modify: `apps/backend/src/app/modules/meeting/meeting.service.ts`

**Details:**
- In `ConversationService.createConversation`:
  - If creator is a Free Citizen and target participant is `DOCTOR` or `MENTAL_HEALTH_PROFESSIONAL`, reject with 403: *"Mental health support and doctor consultations require Govia Premium."*
- In `MeetingService.scheduleMeeting`:
  - If host is a Free Citizen and meeting topic or participant indicates doctor/mental health, reject with 403.

---

### Task 9: Mobile App In-App Purchase Integration & Controller
**Files:**
- Modify: `apps/mobile/pubspec.yaml` (add `in_app_purchase: ^3.2.0`)
- Modify: `apps/mobile/lib/module/shared/subscription/controller/subscription_controller.dart`

**Details:**
- Add `InAppPurchase` listener and lifecycle handlers for:
  - `govia_premium_monthly` ($9.99)
  - `govia_premium_yearly` ($79.99)
- On purchase update -> send receipt/purchaseToken to `/subscriptions/verify-iap` -> on success, refresh user subscription status and update UI.
- Fallback manual upgrade for testing/simulation.
- Store subscription state in GetX reactive variables (`currentPlan`, `usedMeetings`, `limitMeetings`, `isPremium`).

---

### Task 10: Mobile App Subscription Paywall Redesign
**Files:**
- Modify: `apps/mobile/lib/module/shared/subscription/view/subscription_view.dart`

**Visual Redesign:**
- Premium dark/light hybrid design with Govia Navy (`#1550A6`) and Gold/Violet gradients.
- Interactive Monthly vs Yearly toggle switch with *"SAVE 33%"* badge.
- Current Citizen Usage indicator: *"1 of 3 free emergency meetings used this month"*.
- Side-by-side feature comparison table:
  - Emergency Meetings: 3/mo vs Unlimited
  - Incident Video Recordings: ❌ Locked vs Full Cloud Vault & Playback
  - Doctor & Mental Health: ❌ None vs 24/7 Licensed Specialists
  - Legal AI: Community Free AI vs High-Speed GPT-4o Legal Copilot
- Dynamic CTA: *"Upgrade with Google Play / Apple Store ($9.99/mo or $79.99/yr)"*.

---

### Task 11: Mobile Touchpoint Visual Locks & Gating
**Files:**
- Modify: `apps/mobile/lib/module/citizen/home/view/citizen_home_view.dart` (or emergency call button)
- Modify: `apps/mobile/lib/module/citizen/encounter_history/view/encounter_history_view.dart`
- Modify: `apps/mobile/lib/module/citizen/mental_health/view/mental_health_view.dart`
- Modify: `apps/mobile/lib/module/shared/schedule/controller/common_schedule_controller.dart`

**Touchpoints:**
- Emergency / Start Govia: Shows remaining monthly count; if limit is reached (3/3), triggers upgrade dialog.
- Encounter History & Schedule: Shows `🔒 Premium` badge on recordings and opens upgrade dialog when tapped.
- Mental Health: Shows banner *"⭐ Premium Feature: Connect with licensed doctors 24/7"* and prompts upgrade before booking or messaging.

---

### Task 12: Testing & Verification
**Steps:**
1. Run `npm run typecheck` and `npm run lint` in `apps/backend`.
2. Run `flutter pub get` and verify Dart code in `apps/mobile`.
3. Verify that non-citizen roles (Attorney, Police, Doctor, Bondsman, Admin) are never blocked by any subscription gates.
4. Verify that Free Citizens are capped at 3 meetings per calendar month, use rotating free OpenRouter models, and cannot access recordings or doctor chats.
