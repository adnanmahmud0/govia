import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/shared/subscription/controller/subscription_controller.dart';

class SubscriptionView extends GetView<SubscriptionController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // ─── HERO HEADER ───────────────────────────────────────────────
            _buildHeroHeader(context),

            // ─── SCROLLABLE CONTENT ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Live Citizen Quota / Tier Badge
                    _buildCurrentStatusBanner(),

                    SizedBox(height: 16.h),

                    // Billing Cycle Switcher (Monthly vs Yearly)
                    _buildBillingCycleSwitcher(),

                    SizedBox(height: 20.h),

                    // Govia Premium Hero Card
                    _buildPremiumCard(),

                    SizedBox(height: 18.h),

                    // Community Free Tier Comparison Card
                    _buildFreeComparisonCard(),

                    SizedBox(height: 20.h),

                    // Trust Badges
                    _buildTrustBadges(),

                    SizedBox(height: 20.h),

                    // Legal Terms Footer
                    _buildLegalFooter(),

                    SizedBox(height: 80.h), // Bottom button clearance
                  ],
                ),
              ),
            ),
          ],
        ),

        // ─── STICKY BOTTOM SUBSCRIBE CTA ─────────────────────────────────
        bottomNavigationBar: _buildStickyBottomCTA(context),
      ),
    );
  }

  /// Top Hero Header with Govia Navy Gradient
  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1550A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.h,
        left: 20.w,
        right: 20.w,
        bottom: 24.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: const Color(0xFFF59E0B), size: 14.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'CITIZEN PROTECTION',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'Protect What Matters Most',
            style: GoogleFonts.outfit(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Unlimited emergency dispatches, licensed doctor care, and cloud incident vault.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Current Citizen Usage / Tier Banner
  Widget _buildCurrentStatusBanner() {
    return Obx(() {
      final isExempt = !controller.isCitizen.value || controller.currentPlan.value == 'EXEMPT';
      if (isExempt) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1550A6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFF1550A6).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: const Color(0xFF1550A6),
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Professional Exemption Active',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1550A6),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'As a verified partner, your account is exempt from citizen subscriptions.',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final isPrem = controller.isPremium.value;
      final used = controller.usedMeetings.value;
      final limit = controller.limitMeetings.value;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isPrem
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : const Color(0xFF1E293B).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isPrem
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPrem ? Icons.verified_rounded : Icons.info_outline_rounded,
              color: isPrem ? const Color(0xFF059669) : const Color(0xFF1550A6),
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPrem ? 'Active: Govia Premium Citizen' : 'Current: Community Free Plan',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isPrem ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    isPrem
                        ? 'Unlimited emergency calls & full medical access active.'
                        : '$used of $limit free emergency / Govia meetings used this month.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Monthly vs Yearly Interactive Toggle Switch
  Widget _buildBillingCycleSwitcher() {
    return Obx(() {
      final isYearly = controller.selectedBillingCycle.value == 'yearly';

      return Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          children: [
            // Monthly Option
            Expanded(
              child: GestureDetector(
                onTap: () => controller.toggleBillingCycle('monthly'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: !isYearly ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(26.r),
                    boxShadow: !isYearly
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      'Monthly (\$9.99)',
                      style: GoogleFonts.inter(
                        fontSize: 13.5.sp,
                        fontWeight: !isYearly ? FontWeight.w700 : FontWeight.w600,
                        color: !isYearly ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Yearly Option (with Save 33% Badge)
            Expanded(
              child: GestureDetector(
                onTap: () => controller.toggleBillingCycle('yearly'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isYearly ? const Color(0xFF1550A6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(26.r),
                    boxShadow: isYearly
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1550A6).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Yearly',
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: isYearly ? FontWeight.w700 : FontWeight.w600,
                          color: isYearly ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'SAVE 33%',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Govia Premium Featured Plan Card
  Widget _buildPremiumCard() {
    return Obx(() {
      final isYearly = controller.selectedBillingCycle.value == 'yearly';
      final price = isYearly ? '\$79.99' : '\$9.99';
      final interval = isYearly ? '/ year' : '/ month';
      
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFF1550A6), width: 2.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1550A6).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1550A6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Text(
                  '⭐ RECOMMENDED CITIZEN PASS',
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Govia Premium',
                              style: GoogleFonts.outfit(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Complete Legal & Telehealth Suite',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                price,
                                style: GoogleFonts.outfit(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1550A6),
                                ),
                              ),
                              Text(
                                interval,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isYearly ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isYearly ? 'Save \$40 / year' : 'Billed monthly',
                              style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isYearly ? const Color(0xFF15803D) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isYearly) ...[
                    SizedBox(height: 4.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '(\$6.67/month equivalent)',
                        style: GoogleFonts.inter(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 20.h),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                  SizedBox(height: 16.h),

                  // Feature Checklist
                  _buildFeatureRow(
                    'Unlimited 24/7 Emergency & Govia Calls',
                    'Zero call limits, instant live WebRTC connection',
                    isIncluded: true,
                    isHighlight: true,
                  ),
                  _buildFeatureRow(
                    'Full Incident Cloud Video Recordings',
                    'Watch, stream, download, and preserve evidence in Vault',
                    isIncluded: true,
                    isHighlight: true,
                  ),
                  _buildFeatureRow(
                    '24/7 Licensed Doctors & Mental Health',
                    'Direct confidential telehealth video/voice calls',
                    isIncluded: true,
                    isHighlight: true,
                  ),
                  _buildFeatureRow(
                    'Direct Doctor & Specialist Messaging',
                    'Confidential chat with verified healthcare professionals',
                    isIncluded: true,
                  ),
                  _buildFeatureRow(
                    'Advanced Legal AI Copilot (GPT-4o / Claude)',
                    'Highest reasoning depth and immediate legal responses',
                    isIncluded: true,
                  ),
                  _buildFeatureRow(
                    'Priority Emergency Dispatch',
                    'High-priority alerts sent to local attorneys & bondsmen',
                    isIncluded: true,
                  ),
                  _buildFeatureRow(
                    'Tamper-Proof Evidence Vault Exports',
                    'Export certified encounter logs for legal counsel',
                    isIncluded: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Community Free Tier Card
  Widget _buildFreeComparisonCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Community Free Plan',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              Text(
                '\$0 / month',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildFeatureRow(
            '3 Emergency / Start Govia Calls per Month',
            'Essential coverage during traffic stops or emergencies',
            isIncluded: true,
          ),
          _buildFeatureRow(
            'GoVia AI Legal Assistant',
            'Community Free OpenRouter AI model rotation',
            isIncluded: true,
          ),
          _buildFeatureRow(
            'Cloud Video Recording Playback & Archive',
            'Locked on Free plan (Requires Premium)',
            isIncluded: false,
          ),
          _buildFeatureRow(
            'Doctor & Mental Health Consultations',
            'Locked on Free plan (Requires Premium)',
            isIncluded: false,
          ),
        ],
      ),
    );
  }

  /// Helper Feature Row
  Widget _buildFeatureRow(
    String title,
    String subtitle, {
    required bool isIncluded,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(3.r),
            margin: EdgeInsets.only(top: 2.h),
            decoration: BoxDecoration(
              color: isIncluded
                  ? (isHighlight ? const Color(0xFF10B981) : const Color(0xFF1550A6))
                  : const Color(0xFFCBD5E1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncluded ? Icons.check_rounded : Icons.lock_outline_rounded,
              color: Colors.white,
              size: 13.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                    color: isIncluded ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    color: isIncluded ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trust & Security Signals
  Widget _buildTrustBadges() {
    final storeName = Platform.isIOS ? 'App Store' : 'Google Play';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12.w,
        runSpacing: 6.h,
        children: [
          _buildTrustItem(Icons.verified_user_rounded, 'Verified by $storeName'),
          _buildTrustItem(Icons.bolt_rounded, 'Instant Activation'),
          _buildTrustItem(Icons.autorenew_rounded, 'Cancel Anytime'),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5.sp, color: const Color(0xFF1550A6)),
        SizedBox(width: 4.w),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  /// Legal Terms Footer
  Widget _buildLegalFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: const Color(0xFF94A3B8),
            height: 1.5,
          ),
          children: [
            const TextSpan(
              text: 'Subscriptions renew automatically unless cancelled at least 24h before the end of the billing period in your ',
            ),
            TextSpan(
              text: Platform.isIOS ? 'Apple ID Account Settings' : 'Google Play Account',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const TextSpan(text: '. Read our '),
            TextSpan(
              text: 'Terms of Service',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                color: Color(0xFF1550A6),
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Get.toNamed(AppRoutes.termsAndConditions),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                color: Color(0xFF1550A6),
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Get.toNamed(AppRoutes.privacyPolicy),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  /// Sticky Bottom CTA Button
  Widget _buildStickyBottomCTA(BuildContext context) {
    final storeName = Platform.isIOS ? 'Apple Store' : 'Google Play';

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 14.h,
        bottom: MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        final isExempt = !controller.isCitizen.value || controller.currentPlan.value == 'EXEMPT';
        final isPrem = controller.isPremium.value;
        final isPurchasing = controller.isPurchasing.value;
        final isYearly = controller.selectedBillingCycle.value == 'yearly';
        final priceLabel = isYearly ? '\$79.99 / year' : '\$9.99 / month';

        if (isExempt) {
          return SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: () => Get.back(),
              icon: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
              label: Text(
                'Professional Exemption Active',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
            ),
          );
        }

        if (isPrem) {
          return SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: () => Get.back(),
              icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
              label: Text(
                'Govia Premium Active',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.sp),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1550A6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: isPurchasing ? null : controller.subscribe,
                child: isPurchasing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Connecting to $storeName...',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded, color: Colors.white, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Upgrade Now • $priceLabel',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
