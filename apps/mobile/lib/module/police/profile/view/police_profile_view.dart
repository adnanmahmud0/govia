import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/police/profile/controller/police_profile_controller.dart';

class PoliceProfileView extends GetView<PoliceProfileController> {
  const PoliceProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with blue curved background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: MediaQuery.of(context).padding.top + 16.h,
                  bottom: 24.h,
                ),
                child: Row(
                  children: [
                    // Profile Avatar with Verified Badge
                    GestureDetector(
                      onTap: () => controller.openOfficerQrDialog(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Obx(() {
                            final img = controller.avatarUrl.value;
                            return Container(
                              width: 68.r,
                              height: 68.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5.w,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(34.r),
                                child: img.isNotEmpty
                                    ? Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildAvatarFallback(),
                                      )
                                    : _buildAvatarFallback(),
                              ),
                            );
                          }),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(3.r),
                              decoration: const BoxDecoration(
                                color: Color(0xFF047857), // Green verified
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14.w),

                    // Middle details
                    Expanded(
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    controller.name.value.toLowerCase().startsWith('officer')
                                        ? controller.name.value
                                        : 'Officer ${controller.name.value}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'POLICE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              controller.department.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            SizedBox(height: 5.h),

                            // Badge ID Chip + QR Pill + Scan Pill (Overflow-safe)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: controller.copyHexId,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'BADGE #${controller.badgeId.value}',
                                            style: GoogleFonts.sourceCodePro(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
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
                                  SizedBox(width: 6.w),
                                  GestureDetector(
                                    onTap: () => controller.openOfficerQrDialog(initialTabIndex: 0),
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
                                            size: 12.sp,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 3.w),
                                          Text(
                                            'QR Card',
                                            style: GoogleFonts.inter(
                                              fontSize: 9.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
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
                            Row(
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  color: Colors.white70,
                                  size: 13.sp,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    'Speaks: ${controller.languages.value}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Top right actions: QR Scanner circular button + Settings button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: controller.openQrScanner,
                          child: Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.w,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 19.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.policeSettings),
                          child: Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.w,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 19.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Body Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  children: [

                      SizedBox(height: 16.h),

                      // Officer GoVia Credential QR Card
                      GestureDetector(
                        onTap: controller.openOfficerQrDialog,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF1550A6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1550A6).withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.qr_code_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Officer Credential QR',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Show badge & digital credentials',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 14.sp,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'COMMUNITY RATING',
                              child: Text(
                                '4.9 ★',
                                style: GoogleFonts.inter(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: _buildStatCard(
                              title: 'ENCOUNTERS',
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDCFCE7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      color: const Color(0xFF16A34A),
                                      size: 20.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '100% Logged',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'DE-ESCALATION',
                              child: Column(
                                children: [
                                  Container(
                                    width: 52.r,
                                    height: 52.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF047857),
                                        width: 3.w,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '94%',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Excellent',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: _buildStatCard(
                              title: 'GOVIA VERIFIED',
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: const Color(0xFFBFDBFE),
                                        width: 1.w,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.local_police_rounded,
                                          color: const Color(0xFF1E3A8A),
                                          size: 20.sp,
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          'OFFICIAL',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF1E3A8A),
                                          ),
                                        ),
                                        Text(
                                          'Active Duty',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // Profile Options list
                      _buildOptionItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        onTap: () => Get.toNamed(AppRoutes.policePersonalInfo),
                      ),
                      _buildOptionItem(
                        icon: Icons.security_rounded,
                        title: 'Settings & Security',
                        onTap: () => Get.toNamed(AppRoutes.policeSettings),
                      ),
                      _buildOptionItem(
                        icon: Icons.hexagon_outlined,
                        title: 'Referral For Points',
                        onTap: () => Get.toNamed(AppRoutes.referral),
                      ),
                      _buildOptionItem(
                        icon: Icons.card_giftcard_rounded,
                        title: 'Gift Plan',
                        onTap: () => Get.toNamed(AppRoutes.giftingHub),
                      ),
                      _buildOptionItem(
                        icon: Icons.monetization_on_outlined,
                        title: 'Bail Bondsman Directory',
                        onTap: () => controller.showBailBondsmanDirectory(context),
                      ),

                      SizedBox(height: 24.h),

                      // Log Out Button
                      GestureDetector(
                        onTap: controller.confirmLogout,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Log Out',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF1550A6).withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.local_police_rounded,
          color: const Color(0xFF1550A6),
          size: 44.sp,
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required Widget child}) {
    return Container(
      height: 130.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          child,
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final Color itemColor = isDestructive
        ? const Color(0xFFDC2626)
        : const Color(0xFF1550A6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
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
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: itemColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: itemColor.withValues(alpha: 0.5),
              size: 15.sp,
            ),
          ],
        ),
      ),
    );
  }
}

