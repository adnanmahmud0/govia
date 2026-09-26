# Gift Subscription Plan & Redemption System (Consumable IAP & Single-Use Code Engine) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a production-grade, Apple & Google store-compliant Gift Subscription Plan system allowing users of **all roles** (`CITIZEN`, `ATTORNEY`, `DOCTOR`, `POLICE`, `BAIL_BONDSMAN`) to purchase subscription gift passes for others using **Consumable In-App Purchases (IAP)** and direct checkout, distribute single-use cryptographic gift codes, track who redeemed each code with full transparency, and enable recipients to preview and redeem codes to activate citizen safety subscriptions.

**Architecture:**
- **Store-Compliant Consumable IAP:** Auto-renewing subscriptions cannot be gifted directly or dynamically multiplied under Apple/Google rules. Gifting is implemented via **Consumable In-App Purchases** with predefined, approved gift packages (`1 Gift`, `Family Pack (3 Gifts)`, `Team Pack (5 Gifts)`, `Community Pack (10 Gifts)`), alongside direct/sandbox fallback. Consumables can be purchased repeatedly on the same Apple ID / Google account.
- **Backend Architecture (`apps/backend`):** A dedicated `GiftPlan` module with a MongoDB `gift_codes` collection. Uses atomic `$set` operations on `{ code, status: 'AVAILABLE' }` to enforce single-use redemption with zero race conditions. Seamlessly integrates with `SubscriptionService` to activate or extend the recipient's prepaid subscription without touching the recipient's personal Apple/Google payment account.
- **Mobile Experience (`apps/mobile`):** A unified, high-converting Gifting Hub with two segmented tabs:
  1. **"Gift Subscriptions"**: Package picker (Monthly vs. Yearly, Single vs. Bundles), one-tap IAP purchase, instant code generator, copy/share tools, and a real-time tracking list showing which codes are unclaimed and which have been redeemed (revealing recipient name, email, avatar, and timestamp).
  2. **"Redeem Gift Code"**: Monospace code input with paste support, live gift preview displaying the giver's name and unlocked safety features, and a celebratory one-tap activation modal.
  3. **Universal Entry Points**: Accessible from the profile menu of all 5 roles and linked directly from the Citizen paywall.

**Tech Stack:** Node.js, Express.js, TypeScript, Mongoose/MongoDB, Apple StoreKit & Google Play Developer APIs, Flutter 3.x, Dart, GetX, `in_app_purchase: ^3.2.0`, Google Fonts.

---

## StoreKit & Google Play Product SKUs

The system configures fixed **Consumable In-App Purchase** SKUs so users can purchase gifts repeatedly:

| SKU / Product ID | Type | Duration | Units Included | Tier Price | Target Audience |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `govia_gift_monthly_1` | Consumable | 30 Days | 1 Code | $9.99 | Individual Gift |
| `govia_gift_yearly_1` | Consumable | 365 Days | 1 Code | $79.99 | 1-Year VIP Pass (Save 33%) |
| `govia_gift_monthly_3` | Consumable | 30 Days | 3 Codes | $26.99 | Family Pack (Save 10%) |
| `govia_gift_monthly_5` | Consumable | 30 Days | 5 Codes | $44.99 | Team Pack (Save 10%) |
| `govia_gift_monthly_10`| Consumable | 30 Days | 10 Codes | $79.99 | Community/Org Pack (Save 20%) |

*Note: For testing, development, and enterprise web orders, a direct checkout / sandbox provider (`MANUAL` / `STRIPE`) is supported alongside native IAP.*

---

## Data Models & Schema Design

### `IGiftCode` (MongoDB Collection: `gift_codes`)
```typescript
{
  code: string;                  // Unique indexed, format: "GOVIA-GIFT-A8F2-99CD"
  batchId: string;               // UUID grouping codes bought in a single transaction
  purchasedBy: ObjectId;         // Ref: User (any role: Citizen, Attorney, Police, Doctor, Bondsman)
  purchaserName: string;         // Cached for instant display on recipient's gift card
  purchaserRole: string;         // 'ATTORNEY' | 'POLICE' | 'DOCTOR' | 'CITIZEN' | etc.
  purchaserEmail: string;        // Buyer contact email
  plan: 'PREMIUM_MONTHLY' | 'PREMIUM_YEARLY';
  billingCycle: 'MONTHLY' | 'YEARLY';
  durationDays: number;          // 30 or 365
  pricePerUnit: number;          // Unit price paid
  totalBatchPrice: number;       // Total cost of the batch
  quantity: number;              // Total codes in the batch
  status: 'AVAILABLE' | 'REDEEMED' | 'EXPIRED';
  redeemedBy?: ObjectId;         // Ref: User (recipient)
  redeemedByName?: string;       // Name of recipient who used the code
  redeemedByEmail?: string;      // Email of recipient who used the code
  redeemedByAvatar?: string;     // Avatar of recipient
  redeemedAt?: Date;             // Exact redemption timestamp
  expiresAt: Date;               // Default 1 year from purchase
  paymentProvider: 'APPLE_IAP' | 'GOOGLE_PLAY' | 'STRIPE' | 'MANUAL';
  productId: string;             // e.g. "govia_gift_monthly_1"
  purchaseToken?: string;        // App Store receipt or Google purchase token
  transactionId?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## Detailed Implementation Tasks

### Task 1: Backend Gift Plan Interfaces & Mongoose Schema
**Files:**
- Create: `apps/backend/src/app/modules/giftPlan/giftPlan.interface.ts`
- Create: `apps/backend/src/app/modules/giftPlan/giftPlan.model.ts`

**Details:**
1. Define `IGiftCode`, `IGiftPackageOption`, `IGiftPurchasePayload`, `IGiftValidatePayload`, `IGiftRedeemPayload`.
2. Implement Mongoose schema with:
   - Compound unique index on `{ code: 1 }`.
   - Index on `{ purchasedBy: 1, createdAt: -1 }` for the buyer's tracking dashboard.
   - Index on `{ status: 1 }`.
   - Schema-level validation ensuring `redeemedBy` and `redeemedAt` are set simultaneously upon status change to `REDEEMED`.
3. Export `GiftCode` Mongoose model.

---

### Task 2: Backend Gift Plan Service (Purchase, Validation, Atomic Redemption, Tracking)
**Files:**
- Create: `apps/backend/src/app/modules/giftPlan/giftPlan.service.ts`

**Key Methods:**
1. `getGiftPackages()`:
   - Returns available consumable packages with SKUs, unit counts, prices, and savings badges.
2. `generateSecureGiftCodes(count: number)`:
   - Cryptographically generates readable alphanumeric codes (e.g. `GOVIA-GIFT-W7X2-99AB`) using uppercase letters and numbers (excluding ambiguous characters `0, O, 1, I`).
   - Checks uniqueness against database before insertion.
3. `purchaseGiftPackage(purchaserId, purchaserRole, payload)`:
   - Validates package selection (`productId`, `plan`, `quantity`).
   - If `APPLE_IAP` or `GOOGLE_PLAY`, verifies consumable purchase receipt via `appleIap.service` / `googlePlay.service`.
   - Generates $N$ distinct codes under a shared `batchId`.
   - Inserts codes into `gift_codes` collection.
   - Returns `{ batchId, totalCodes: count, codes: [...] }`.
4. `getMyPurchasedGifts(purchaserId)`:
   - Queries `GiftCode.find({ purchasedBy: purchaserId }).sort({ createdAt: -1 })`.
   - Returns all active and redeemed codes.
   - For redeemed codes, includes `redeemedByName`, `redeemedByEmail`, `redeemedByAvatar`, and `redeemedAt` so the buyer can see **who used the code**.
5. `validateGiftCode(code)`:
   - Cleans code string (trims whitespace, converts to uppercase).
   - Looks up code in `gift_codes`.
   - If not found: Throws `404 - Invalid gift code`.
   - If `status === 'REDEEMED'`: Throws `400 - This gift code has already been redeemed`.
   - If `status === 'EXPIRED'` or `expiresAt < now`: Throws `400 - This gift code has expired`.
   - Returns preview metadata: `{ valid: true, plan, durationDays, purchaserName, purchaserRole, expiresAt }`.
6. `redeemGiftCode(recipientUserId, recipientRole, code)`:
   - Atomic update:
     ```typescript
     const updated = await GiftCode.findOneAndUpdate(
       { code: cleanCode, status: 'AVAILABLE' },
       {
         $set: {
           status: 'REDEEMED',
           redeemedBy: recipientUserId,
           redeemedByName: recipientUser.name,
           redeemedByEmail: recipientUser.email,
           redeemedByAvatar: recipientUser.image || recipientUser.profilePicture,
           redeemedAt: new Date(),
         },
       },
       { new: true }
     );
     ```
   - If `!updated`: Checks if code was already redeemed or invalid and returns appropriate error message.
   - Calls `SubscriptionService.activateGiftSubscription(recipientUserId, plan, durationDays)`:
     - Activates `PREMIUM_MONTHLY` or `PREMIUM_YEARLY` for the recipient.
     - If the recipient already has an active subscription, safely extends their `endDate` by the gift's duration.
   - Returns success payload with subscription details and celebration message.

---

### Task 3: Backend Controller, Zod Validation & Express Routes
**Files:**
- Create: `apps/backend/src/app/modules/giftPlan/giftPlan.validation.ts`
- Create: `apps/backend/src/app/modules/giftPlan/giftPlan.controller.ts`
- Create: `apps/backend/src/app/modules/giftPlan/giftPlan.route.ts`
- Modify: `apps/backend/src/routes/v1/index.ts`

**Endpoints:**
- `GET /api/v1/gift-plans/packages`: Public / Authenticated. Returns configured gift packages and pricing.
- `POST /api/v1/gift-plans/purchase`: Authenticated (`allRoles`). Validates `{ productId, plan, quantity, provider, token? }`.
- `GET /api/v1/gift-plans/my-purchases`: Authenticated (`allRoles`). Returns buyer's purchased gift codes and redemption tracking info.
- `POST /api/v1/gift-plans/validate`: Authenticated (`allRoles`). Validates `{ code }` and returns gift card preview.
- `POST /api/v1/gift-plans/redeem`: Authenticated (`allRoles`). Validates `{ code }` and activates recipient subscription.

---

### Task 4: Mobile Data Models & API Service
**Files:**
- Create: `apps/mobile/lib/module/shared/gifting/models/gift_package_model.dart`
- Create: `apps/mobile/lib/module/shared/gifting/models/gift_code_model.dart`
- Create: `apps/mobile/lib/module/shared/gifting/services/gifting_api_service.dart`

**Details:**
1. `GiftPackageModel`:
   - `id`, `productId`, `title`, `plan`, `unitsCount`, `price`, `badge`, `discountText`, `description`
2. `GiftCodeModel`:
   - `code`, `plan`, `price`, `status`, `purchasedAt`, `expiresAt`
   - `isRedeemed`, `redeemedByName`, `redeemedByEmail`, `redeemedByAvatar`, `redeemedAt`
3. `GiftingApiService`:
   - `fetchPackages()`
   - `purchaseGiftPackage({required String productId, required String plan, required int quantity, required String provider, String? token})`
   - `fetchMyPurchasedGifts()`
   - `validateGiftCode(String code)`
   - `redeemGiftCode(String code)`

---

### Task 5: Mobile Gifting Controller with IAP Consumable Stream
**Files:**
- Modify: `apps/mobile/lib/module/shared/gifting/controller/gifting_controller.dart`
- Modify: `apps/mobile/lib/module/shared/gifting/binding/gifting_binding.dart`

**Controller Logic:**
1. **Tabs:** Reactive `selectedTab` (`0 = "Gift Subscriptions"`, `1 = "Redeem Code"`).
2. **IAP Integration:** Listens to `InAppPurchase.instance.purchaseStream` for consumable purchases (`govia_gift_*`). On purchase completion, verifies with backend and automatically refreshes "My Gifted Codes".
3. **Gift Code Actions:**
   - `copyCode(String code)`: Copies code to clipboard and displays snackbar.
   - `shareCode(GiftCodeModel code)`: Uses system share sheet with tailored message:
     *"Here is your Govia Safety & Protection subscription gift from [User Name]! CODE: [CODE]. Open the Govia app and enter this code in the Gifting Hub to unlock full emergency coverage!"*
4. **Redemption State Machine:**
   - `codeController`: Text editing controller with auto-uppercase and clean formatting.
   - `previewState`: `idle` | `loading` | `previewLoaded` | `redeeming` | `success` | `error`.
   - `verifiedGiftPreview`: Reactive object containing giver's name, plan, and benefits.
   - `redeemCurrentCode()`: Calls API, shows celebration dialog, and refreshes user subscription status.

---

### Task 6: Mobile Gifting Hub UI (Segmented Tabs & Tracking Dashboard)
**Files:**
- Modify: `apps/mobile/lib/module/shared/gifting/view/gifting_hub_view.dart`
- Create: `apps/mobile/lib/module/shared/gifting/widgets/gift_package_selector.dart`
- Create: `apps/mobile/lib/module/shared/gifting/widgets/my_gifted_codes_list.dart`

**UI Features:**
1. **Segmented Tab Switcher:**
   - Sleek dark/light pill toggle: `[ 🎁 Gift Subscriptions ]` `[ 🎟️ Redeem Code ]`.
2. **Tab 1 ("Gift Subscriptions"):**
   - **Predefined Pack Cards:**
     - `1 Month Gift` ($9.99)
     - `1 Year VIP Gift` ($79.99 • Best Value)
     - `Family Pack (3 Gifts)` ($26.99 • Save 10%)
     - `Team Pack (5 Gifts)` ($44.99 • Save 10%)
     - `Community Pack (10 Gifts)` ($79.99 • Save 20%)
   - **One-Tap Purchase Button:**
     - Triggers native StoreKit / Google Play consumable purchase or direct checkout.
   - **"My Gifted Codes" Real-Time Section:**
     - Shows each code with copy button, share button, and status pill.
     - **"Who Used It" Card:** When a code is redeemed, displays:
       - Recipient's Name & Email: `Alex Rivera (alex@...)`
       - Redemption Timestamp: `Redeemed on Sep 26, 2026 at 10:15 AM`
       - Green checkmark verified badge.
3. **Tab 2 ("Redeem Code"):**
   - Input card with monospace code field, clear button, and paste button.
   - "Verify Code" CTA button.

---

### Task 7: Mobile Gift Redemption Preview & Celebration Dialog
**Files:**
- Create: `apps/mobile/lib/module/shared/gifting/view/redeem_gift_section.dart`
- Create: `apps/mobile/lib/module/shared/gifting/widgets/gift_preview_card.dart`
- Create: `apps/mobile/lib/module/shared/gifting/widgets/redemption_success_dialog.dart`

**UX Flow:**
1. When verified, renders a golden/blue digital **Govia Gift Card**:
   - Giver's greeting: *"Gift from Attorney Sarah Jenkins"*
   - Plan details: *"1 Month Premium Citizen Protection"*
   - Full list of unlocked privileges (Unlimited emergency meetings, full video recording vault, 24/7 doctor chat, AI copilot).
2. **"Accept & Activate Subscription" CTA Button:**
   - Tapping it sends redemption request to backend.
   - Triggers `RedemptionSuccessDialog` with celebratory animation, instantly updates app-wide subscription state, and guides user to their new features.
3. **Single-Use Guard:**
   - If the code was already used, displays a clear, helpful warning: *"This code was already redeemed on [Date] by [User]."*

---

### Task 8: Cross-Role Navigation & Paywall Integration
**Files:**
- Modify: `apps/mobile/lib/module/citizen/profile/view/citizen_profile_view.dart`
- Modify: `apps/mobile/lib/module/attorney/profile/view/attorney_profile_view.dart`
- Modify: `apps/mobile/lib/module/doctore/profile/view/doctor_profile_view.dart`
- Modify: `apps/mobile/lib/module/police/profile/view/police_profile_view.dart`
- Modify: `apps/mobile/lib/module/bail_bondsman/profile/view/bail_bondsman_profile_view.dart`
- Modify: `apps/mobile/lib/module/shared/subscription/view/subscription_view.dart`

**Updates:**
1. Ensure the Profile menu in **all 5 roles** has the "Gifting Hub" tile:
   - Title: `Gifting Hub`
   - Subtitle: `Gift safety subscriptions to family or clients`
   - Tap: `Get.toNamed(AppRoutes.giftingHub)`
2. In `subscription_view.dart` (Citizen Paywall), add a bottom action banner:
   - *"Have a Gift Code? [Redeem Here]"* -> Opens `AppRoutes.giftingHub` with the Redeem tab active.

---

### Task 9: Verification & Automated Testing
1. **Backend Build & Verification:**
   - `npm run build` in `apps/backend` to verify TypeScript typing and imports.
2. **Mobile Validation:**
   - `flutter analyze lib/module/shared/gifting` to guarantee 0 errors and clean code.
3. **End-to-End Scenarios:**
   - **Scenario A:** Buy a 3-pack of gifts -> Verify 3 unique codes are generated.
   - **Scenario B:** Copy and share code -> Verify formatting and readability.
   - **Scenario C:** Log in as another citizen -> Enter code -> Preview gift -> Accept -> Verify subscription is activated and valid for 30 days.
   - **Scenario D:** Try entering the same code a second time -> Verify system blocks it with single-use error.
   - **Scenario E:** Switch back to buyer account -> Check "My Gifted Codes" -> Verify code status shows `REDEEMED` with the recipient's name and exact redemption timestamp.
