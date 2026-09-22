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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Light App Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: const Color(0xFF1550A6),
                          size: 18.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Subscription',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              // Plan List Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12.h),
                      Text(
                        'Choose Your Plan',
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Select the plan that fits your needs',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFF5F6E80),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Plan Cards
                      Obx(
                        () => Column(
                          children: controller.plans.map((plan) {
                            final isSelected =
                                controller.selectedPlanId.value == plan.id;
                            return _buildPlanCard(plan, isSelected);
                          }).toList(),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Terms and Privacy policy footer
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'By subscribing, you agree to our ',
                                ),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF475569),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.toNamed(AppRoutes.termsAndConditions);
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF475569),
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.toNamed(AppRoutes.privacyPolicy);
                                    },
                                ),
                                const TextSpan(text: '.\nCancel anytime.'),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Subscribe Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1550A6),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          onPressed: controller.subscribe,
                          child: Text(
                            'Subscribe Now',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan, bool isSelected) {
    // Determine color schemes based on plan ID
    Color themeColor;
    Color badgeBgColor;
    Color badgeTextColor;
    bool isBadgeOnBorder = false;

    switch (plan.id) {
      case 'free':
        themeColor = const Color(0xFF10B981);
        badgeBgColor = const Color(0xFFD1FAE5);
        badgeTextColor = const Color(0xFF065F46);
        break;
      case 'basic':
        themeColor = const Color(0xFF2563EB);
        badgeBgColor = const Color(0xFF2563EB);
        badgeTextColor = Colors.white;
        isBadgeOnBorder = true; // Sits on top border
        break;
      case 'preferred':
        themeColor = const Color(0xFF2563EB);
        badgeBgColor = Colors.transparent;
        badgeTextColor = Colors.transparent;
        break;
      case 'enterprise':
      default:
        themeColor = const Color(0xFF8B5CF6);
        badgeBgColor = const Color(0xFFF3E8FF);
        badgeTextColor = const Color(0xFF6B21A8);
        break;
    }

    final double topMargin = isBadgeOnBorder ? 12.h : 0.h;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => controller.selectPlan(plan.id),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 20.h, top: topMargin),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? themeColor : const Color(0xFFE2E8F0),
                width: isSelected ? 2.w : 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.04 : 0.015,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inner Badge (if not sitting on border)
                if (plan.badge != null && !isBadgeOnBorder) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      plan.badge!,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                // Row with Title & Radio Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.title,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      width: 20.r,
                      height: 20.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? themeColor
                              : const Color(0xFFCBD5E1),
                          width: 1.5.w,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10.r,
                                height: 10.r,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Price Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.price,
                      style: GoogleFonts.inter(
                        fontSize: plan.price.contains('Custom') ? 22.sp : 28.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (!plan.price.contains('Custom')) ...[
                      SizedBox(width: 4.w),
                      Text(
                        '/month',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),

                if (plan.id == 'enterprise') ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Example: 30 members',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                SizedBox(height: 8.h),
                Text(
                  plan.description,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Divider(height: 28.h, color: const Color(0xFFF1F5F9)),

                // Features List
                Column(
                  children: plan.features.map((feature) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: themeColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        // Most Popular Outer Border Badge
        if (isBadgeOnBorder && plan.badge != null)
          Positioned(
            top: 2.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  plan.badge!,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
