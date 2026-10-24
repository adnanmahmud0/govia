# Admin-Configured Service Charge System (No Provider Pricing & No Payouts) Implementation Plan

> **For Claude / Antigravity:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Transform the Preferred Provider system so that:
1. Attorneys and Bail Bondsmen ("billboard men") can **no longer** set individual service prices.
2. The entire **Provider Payout / Stripe Connect Transfer feature is removed** (no provider Stripe onboarding, no Stripe transfers, no meeting encounter auto-payouts).
3. The **Admin sets the Service Charges** in the Admin Dashboard (e.g. Attorney Service Charge, Bail Bondsman Service Charge).
4. **Users pay the Service Charge** directly to GoVia via Stripe Checkout.
5. Once paid, users can **add/select their preferred Attorney and Bail Bondsman** freely from the directory, QR scanner, or ID lookup.

**Architecture:**
1. **Centralized Platform Pricing (Admin-Managed):** Service charges are set by Platform Admins in MongoDB (`CommissionSetting` / `ServiceSetting`) and retrieved via public/admin APIs. All revenue flows directly to GoVia.
2. **Payout & Provider Stripe Elimination:** 
   - Deprecate/remove Stripe Express Connect account creation, account link onboarding, payout status polling, and `stripe.transfers.create`.
   - Remove encounter auto-payout from `MeetingService.endMeeting`.
   - Remove "Service Pricing & Stripe Payouts" menu item and screens from the mobile app for Attorney & Bail Bondsman profiles.
   - Provider Directory simply lists active, verified practitioners without requiring Stripe payout verification or showing provider fees.
3. **Gated Preferred Selection:** 
   - Citizens must have active paid coverage (`preferredAttorneyActiveUntil > Date.now()` / `preferredBailBondsmanActiveUntil > Date.now()`).
   - If unpaid: Citizen is prompted to pay the Admin-set service fee via Stripe Checkout.
   - If active: Citizen can select their preferred Attorney and Bail Bondsman with instant linking (no secondary checkout).

**Tech Stack:**
- **Backend:** Node.js, Express, TypeScript, MongoDB (Mongoose), Stripe API (Standard Checkout & Webhooks), Zod
- **Admin Dashboard:** Next.js (App Router), React, Tailwind CSS, Lucide Icons
- **Mobile App:** Flutter, Dart, GetX, Flutter ScreenUtil, Stripe WebView Modal

---

## Architecture & Workflow Diagram

```mermaid
flowchart TD
    subgraph Admin ["1. Admin Dashboard (/provider-finance)"]
        A1[Admin Sets Monthly Service Charges] --> A2[DB: CommissionSetting / ServiceSetting]
        A2 --> A3[Attorney Service Fee e.g. $49/mo & Bondsman Fee e.g. $29/mo]
        A4[View Total Platform Service Revenue]
    end

    subgraph ProviderApp ["2. Attorney & Bail Bondsman Profiles"]
        P1[Mobile Provider Profile] --> P2[Service Pricing Inputs REMOVED]
        P1 --> P3[Stripe Payout Setup & Transfers REMOVED]
        P1 --> P4[Only Standard Profile Information Maintained]
    end

    subgraph CitizenPayment ["3. Citizen Service Payment"]
        C1[Citizen Opens Preferred Providers Screen] --> C2{Is Service Coverage Active?}
        C2 -->|No / Expired| C3[Prompt: 'Pay Service Charge ($X/mo)' Button]
        C3 --> C4[POST /api/v1/provider-payment/service-checkout]
        C4 --> C5[Stripe Checkout - Direct Payment to Platform]
        C5 --> C6[Payment Verified: Coverage Active for 30 Days]
    end

    subgraph CitizenSelection ["4. Preferred Provider Selection"]
        C6 --> C7[Selection Unlocked]
        C2 -->|Yes / Active| C7
        C7 --> C8[Browse Directory, Scan QR, or Enter ID]
        C8 --> C9[Instant 'Select as Preferred' - NO Provider Fee, NO Transfer]
        C9 --> C10[Preferred Provider Saved to Profile]
    end
```

---

## Detailed Task Breakdown

### Phase 1: Database & Backend Architecture Updates

#### Task 1: Update Platform Settings Model & Schema
**Files:**
- Modify: `apps/backend/src/app/modules/providerPayment/providerPayment.interface.ts`
- Modify: `apps/backend/src/app/modules/providerPayment/providerPayment.model.ts`
- Modify: `apps/backend/src/app/modules/providerPayment/providerPayment.validation.ts`

**Details:**
1. In `providerPayment.interface.ts`:
   - Extend `ICommissionSetting`:
     ```typescript
     export type ICommissionSetting = {
       attorneyServiceFee: number; // e.g. 50 (USD / month)
       bailBondsmanServiceFee: number; // e.g. 30 (USD / month)
       platformCommissionPercent?: number;
       updatedBy?: Types.ObjectId;
       createdAt?: Date;
       updatedAt?: Date;
     };
     ```
   - In `IProviderTransaction`:
     - Make `providerId` optional (platform fee transactions are between Citizen and GoVia Platform).
     - Make `providerAmount`, `platformFee`, `stripeTransferId` optional / 0 (since 100% of the service fee is platform revenue, no payout transfer is performed).
2. In `providerPayment.model.ts`:
   - Add `attorneyServiceFee` (default: 50) and `bailBondsmanServiceFee` (default: 30) to `commissionSettingSchema`.
   - Update `providerTransactionSchema`: `providerId` optional, remove required constraint from `providerAmount`/`platformFee`.
3. In `providerPayment.validation.ts`:
   - Add `updateServiceChargeZodSchema`:
     ```typescript
     const updateServiceChargeZodSchema = z.object({
       body: z.object({
         attorneyServiceFee: z.number().min(0, 'Fee must be non-negative').optional(),
         bailBondsmanServiceFee: z.number().min(0, 'Fee must be non-negative').optional(),
       }),
     });
     ```
   - Add `createServiceCheckoutSessionZodSchema`:
     ```typescript
     const createServiceCheckoutSessionZodSchema = z.object({
       body: z.object({
         role: z.enum(['ATTORNEY', 'BAIL_BONDSMAN']),
         successUrl: z.string().url().optional(),
         cancelUrl: z.string().url().optional(),
       }),
     });
     ```

#### Task 2: Remove Payouts and Provider-Pricing from Backend
**Files:**
- Modify: `apps/backend/src/app/modules/providerPayment/providerPayment.service.ts`
- Modify: `apps/backend/src/app/modules/providerPayment/providerPayment.controller.ts`
- Modify: `apps/backend/src/app/modules/providerPayment/providerPayment.route.ts`
- Modify: `apps/backend/src/app/modules/meeting/meeting.service.ts`

**Details:**
1. In `apps/backend/src/app/modules/meeting/meeting.service.ts`:
   - In `endMeeting`: Remove the block calling `processEncounterAutoPayout` (lines 1290-1304). No auto-payouts on meeting end.
2. In `providerPayment.service.ts`:
   - Remove/deprecate `createStripeExpressAccount`, `getStripeAccountStatus`, `getStripeDashboardLink`, and `processEncounterAutoPayout`.
   - In `updatePricingProfile`: Remove ability for providers to set `serviceFee` and `monthlyServiceFee`.
   - In `getProviderDirectory`: Remove reliance on `payoutsEnabled` or custom `monthlyServiceFee`/`serviceFee`. Providers are listed based on active status, verification, specialization, and ratings.
   - In `verifyAndActivateSession`: Remove `stripe.transfers.create` (no transfer to provider's Stripe account).
3. In `providerPayment.route.ts`:
   - Remove routes:
     - `/payout/onboard`, `/payout-account`, `/payout/account`
     - `/payout/status`, `/payout-status`
     - `/payout/dashboard-link`, `/payout-dashboard`
   - Add new routes:
     - `GET /provider-payment/service-charge`: Public/authenticated endpoint returning current Admin-set service charges (`attorneyServiceFee`, `bailBondsmanServiceFee`).
     - `PUT /provider-payment/admin/service-charge`: Admin endpoint to update service charges.
     - `POST /provider-payment/service-checkout`: Citizen checkout session creation for the service charge.
     - `POST /provider-payment/select-preferred`: Gated provider selection endpoint. Validates that citizen has active paid coverage (`preferredAttorneyActiveUntil > Date.now()` etc.).

#### Task 3: Enforce Gated Preferred Provider Selection in User Service
**Files:**
- Modify: `apps/backend/src/app/modules/user/user.service.ts`

**Details:**
- In `updateProfileToDB`: If the payload attempts to set or update `preferredAttorney` or `preferredBailBondsman` and the caller is not an Admin:
  - Check whether `isExistUser.preferredAttorneyActiveUntil > new Date()` (or bail bondsman equivalent).
  - If coverage is missing or expired, throw `ApiError(StatusCodes.PAYMENT_REQUIRED, 'Active service coverage required. Please pay the service charge first.')`.

---

### Phase 2: Admin Dashboard Refactoring (`apps/admin`)

#### Task 4: Admin Dashboard UI for Service Charges & Revenue
**Files:**
- Modify: `apps/admin/src/app/(dashboard)/provider-finance/page.tsx`
- Modify: `apps/admin/src/components/dashboard/Sidebar.tsx`

**Details:**
1. In `Sidebar.tsx`:
   - Update navigation label from `"Provider Payouts"` to `"Service Charges & Revenue"` (or `"Service Finance"`).
2. In `apps/admin/src/app/(dashboard)/provider-finance/page.tsx`:
   - Change page title to **Platform Service Charges & Revenue**.
   - Subtitle: *"Manage global citizen service charges for Preferred Attorneys and Bail Bondsmen, and view platform revenues."*
   - Replace the Payout Simulator and Commission slider with a **Platform Service Charges Configuration Card**:
     - **Preferred Attorney Monthly Service Charge ($):** Number input (default: e.g. \$49.00).
     - **Preferred Bail Bondsman Monthly Service Charge ($):** Number input (default: e.g. \$29.00).
     - **Save Service Charges Button:** Calls `PUT /api/v1/provider-payment/admin/service-charge` with loading state and success toast.
   - Summary Metric Cards:
     - **Total Service Revenue ($):** Total gross revenue from citizen service charges.
     - **Active Protected Citizens:** Number of citizens with active coverage.
     - **Total Service Subscriptions:** Total completed transactions count.
   - Transactions Table:
     - Remove "Provider Payout" and "Net Payout" columns.
     - Display: Transaction ID, Citizen Name & Email, Service Type (Attorney / Bail Bondsman Protection), Amount Paid ($), Date, Status (COMPLETED/PENDING).

---

### Phase 3: Mobile Provider App Updates (`apps/mobile`)

#### Task 5: Completely Remove Provider Pricing & Payout Screen
**Files:**
- Modify: `apps/mobile/lib/config/routes/app_pages.dart`
- Modify: `apps/mobile/lib/module/attorney/profile/view/attorney_profile_view.dart`
- Modify: `apps/mobile/lib/module/bail_bondsman/profile/view/bail_bondsman_profile_view.dart`
- Clean up/Remove: `apps/mobile/lib/module/shared/provider_pricing_payouts/`

**Details:**
1. In `attorney_profile_view.dart` (lines 341-345):
   - Remove the menu item tile: `"Service Pricing & Stripe Payouts"` (`onTap: () => Get.toNamed(AppRoutes.providerPricingPayouts)`).
2. In `bail_bondsman_profile_view.dart` (lines 258-262):
   - Remove the menu item tile: `"Service Pricing & Stripe Payouts"` (`onTap: () => Get.toNamed(AppRoutes.providerPricingPayouts)`).
3. In `apps/mobile/lib/config/routes/app_pages.dart`:
   - Remove or deprecate `AppRoutes.providerPricingPayouts`.
4. In `provider_pricing_payouts/`:
   - Remove this unused module or leave an empty stub if needed for compilation safety.

---

### Phase 4: Mobile Citizen Flow: Pay Service Charge -> Add Preferred Provider

#### Task 6: Preferred Providers Repository & Controller Updates
**Files:**
- Modify: `apps/mobile/lib/data/repositories/provider_payment_repository.dart`
- Modify: `apps/mobile/lib/module/shared/preferred_providers/controller/preferred_providers_controller.dart`

**Details:**
1. In `provider_payment_repository.dart`:
   - Remove payout methods (`createPayoutAccount`, `getPayoutStatus`, `getPayoutDashboardLink`).
   - Add `getServiceChargeSettings()`: Calls `GET /provider-payment/service-charge`.
   - Add `createServiceCheckoutSession({required String role})`: Calls `POST /provider-payment/service-checkout`.
   - Add `selectPreferredProvider({required String providerId, required bool forAttorney})`: Calls `POST /provider-payment/select-preferred`.
2. In `preferred_providers_controller.dart`:
   - Add state:
     - `final RxDouble attorneyServiceFee = 50.0.obs;`
     - `final RxDouble bailBondsmanServiceFee = 30.0.obs;`
     - `final RxBool isAttorneyCoverageActive = false.obs;`
     - `final RxBool isBondsmanCoverageActive = false.obs;`
   - On initialization:
     - Fetch current service charges via `getServiceChargeSettings()`.
     - Check if user's coverage dates (`preferredAttorneyActiveUntil` / `preferredBailBondsmanActiveUntil`) are in the future:
       ```dart
       isAttorneyCoverageActive.value = user?.preferredAttorneyActiveUntil != null &&
           user!.preferredAttorneyActiveUntil!.isAfter(DateTime.now());
       isBondsmanCoverageActive.value = user?.preferredBailBondsmanActiveUntil != null &&
           user!.preferredBailBondsmanActiveUntil!.isAfter(DateTime.now());
       ```
   - Add `startServiceChargeCheckout({required bool forAttorney})`:
     - Calls `createServiceCheckoutSession(role: forAttorney ? 'ATTORNEY' : 'BAIL_BONDSMAN')`.
     - Opens `StripeWebviewModal`.
     - On payment completion, refreshes user profile (`_authService.getProfile()`) and updates coverage status to active.
   - In `openProviderMarketplaceSheet`:
     - If coverage is NOT active for the selected role:
       - Show modal: *"Legal Protection Service Fee Required. Please pay the monthly service charge of \$${fee.toStringAsFixed(2)} to select and retain a preferred provider."*
       - CTA: *"Pay Service Charge (\$${fee.toStringAsFixed(2)})"*.
     - If coverage IS active:
       - Open marketplace directory.
       - Tapping a provider directly calls `selectPreferredProvider(provider.id)`, instantly linking them without requiring payment or provider-specific checkout.
   - Also gate QR scan, ID lookup, and contacts picker behind `isAttorneyCoverageActive` / `isBondsmanCoverageActive`.

#### Task 7: Preferred Providers UI Polish
**Files:**
- Modify: `apps/mobile/lib/module/shared/preferred_providers/view/preferred_providers_view.dart`
- Modify: `apps/mobile/lib/module/shared/preferred_providers/controller/preferred_providers_controller.dart` (marketplace sheet)

**Details:**
1. In `preferred_providers_view.dart`:
   - On the Preferred Attorney card:
     - If active: Show badge `"Active Coverage until MM/DD/YYYY"`. Show selected attorney name, avatar, and "Change" button.
     - If inactive: Show badge `"Service Fee Required"`. Display prominent CTA button: `"Pay Attorney Service Fee ($X/mo) to Activate"`.
   - On the Preferred Bail Bondsman card:
     - If active: Show badge `"Active Coverage until MM/DD/YYYY"`. Show selected bondsman name, avatar, and "Change" button.
     - If inactive: Show badge `"Service Fee Required"`. Display prominent CTA button: `"Pay Bondsman Service Fee ($Y/mo) to Activate"`.
2. In Marketplace bottom sheet:
   - Remove individual provider fee text (`$X/mo` or `$Y/call`).
   - Show provider rating, bar license / bond agency number, states, and specialization.
   - Button text: `"Select as Preferred Attorney"` / `"Select as Preferred Bail Bondsman"` (instant action).

---

### Phase 5: Verification & Quality Assurance

#### Task 8: Verification
1. **Admin Portal:**
   - Verify Admin can view and modify service charges (e.g. Attorney: $49/mo, Bail Bondsman: $29/mo).
   - Verify sidebar and finance page no longer display payout / Stripe Connect information.
2. **Provider Profile (Mobile):**
   - Verify Attorney and Bail Bondsman profile menus no longer display "Service Pricing & Stripe Payouts".
3. **Citizen Payment & Selection (Mobile):**
   - Verify un-subscribed citizen cannot select a preferred attorney or bondsman and is prompted with the "Pay Service Charge" dialog.
   - Complete test Stripe payment for the service charge. Verify citizen coverage date is extended by 30 days.
   - Verify citizen can now pick an attorney and bail bondsman with immediate linking and zero provider-specific checkout.
4. **Emergency Encounter:**
   - Verify ending an emergency meeting does not trigger any Stripe transfer or payout error.
