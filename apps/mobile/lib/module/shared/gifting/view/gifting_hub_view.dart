import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/shared/gifting/controller/gifting_controller.dart';

class GiftingHubView extends GetView<GiftingController> {
  const GiftingHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Light App Bar (Back button only)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: const Color(0xFF1550A6),
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // Main Title & Subtitle
                Text(
                  'Gifting Hub',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Secure legal protection and safety credits for your circle.',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 24.h),

                // Card 1: Gift Family & Friends
                _buildGiftCard(
                  icon: Icons.hub_outlined,
                  iconBgColor: const Color(0xFF0A192F),
                  iconColor: Colors.white,
                  title: 'Gift Family & Friends',
                  subtitle: 'Individual protection plans for loved ones.',
                  actionText: 'GET STARTED',
                  onTap: () => controller.giftFamily(),
                ),

                SizedBox(height: 20.h),

                // Card 2: Organization Bulk Gifting
                _buildGiftCard(
                  icon: Icons.corporate_fare_rounded,
                  iconBgColor: const Color(0xFFE2E8F0),
                  iconColor: const Color(0xFF0F172A),
                  title: 'Organization Bulk Gifting',
                  subtitle: 'Scale safety protocols for entire teams.',
                  actionText: 'CONFIGURE ENTERPRISE',
                  onTap: () => controller.configureEnterprise(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
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
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  actionText,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1550A6),
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: const Color(0xFF1550A6),
                  size: 18.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
