import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/bail_bondsman/profile/controller/bail_bondsman_profile_controller.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class BailBondsmanProfileView extends GetView<BailBondsmanProfileController> {
  const BailBondsmanProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Curved Blue Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1550A6), Color(0xFF114FA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16.h,
                bottom: 24.h,
                left: 20.w,
                right: 20.w,
              ),
              child: Row(
                children: [
                  // Profile image
                  Container(
                    width: 68.r,
                    height: 68.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.w),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34.r),
                      child: Obx(() {
                        final url = controller.avatarUrl.value;
                        if (url.isNotEmpty) {
                          return Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAvatarFallback(),
                          );
                        }
                        return _buildAvatarFallback();
                      }),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Obx(
                                () => Text(
                                  controller.name.value,
                                  style: GoogleFonts.inter(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                'BAIL BONDSMAN',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Obx(
                          () => Text(
                            'License: ${controller.licenseNumber.value}',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Short Hex ID Chip with Copy & QR Modal (Overflow-safe)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: controller.copyHexId,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ID: #${controller.shortHexId}',
                                        style: GoogleFonts.sourceCodePro(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 11.sp,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: controller.openQrDialog,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 0.8.w,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 13.sp,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        'QR Card',
                                        style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 4.h),
                        Obx(
                          () => Row(
                            children: [
                              Icon(
                                Icons.language_rounded,
                                color: Colors.white70,
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  'Speaks: ${controller.languages.value}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Account & Settings Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                'Account & Settings',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Settings List Options
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.payments_outlined,
                      title: 'Service Pricing & Stripe Payouts',
                      onTap: () => Get.toNamed(AppRoutes.providerPricingPayouts),
                    ),
                    _buildMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      onTap: () => Get.toNamed(AppRoutes.bailBondsmanPersonalInfo),
                    ),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Setting',
                      onTap: () => Get.toNamed(AppRoutes.bailBondsmanSettings),
                    ),
                    _buildMenuItem(
                      icon: Icons.videocam_outlined,
                      title: 'Encounter History',
                      onTap: () => Get.toNamed(AppRoutes.bailBondsmanHistory),
                    ),
                    _buildMenuItem(
                      icon: Icons.hexagon_outlined,
                      title: 'Referral For Points',
                      onTap: () => Get.toNamed(AppRoutes.referral),
                    ),
                    _buildMenuItem(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Gift Plan',
                      onTap: () => Get.toNamed(AppRoutes.giftingHub),
                    ),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      isDestructive: true,
                      onTap: () => _confirmLogout(context),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.white24,
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: 32.sp,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Log Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out of your Bail Bondsman account?',
          style: GoogleFonts.inter(color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final Color itemColor = isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF4A729F);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 22.sp),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: itemColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFFCBD5E1),
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }
}
