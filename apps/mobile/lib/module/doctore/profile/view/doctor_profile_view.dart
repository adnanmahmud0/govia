import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/constants/image_paths.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/doctore/profile/controller/doctor_profile_controller.dart';

class DoctorProfileView extends GetView<DoctorProfileController> {
  const DoctorProfileView({super.key});

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
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 24.w,
                  right: 24.w,
                  top: MediaQuery.of(context).padding.top + 20.h,
                  bottom: 24.h,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.updateProfileImage(),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Obx(() {
                              final hasUrl = controller.avatarUrl.value.isNotEmpty;
                              final fullUrl = ApiConstants.getFileUrl(
                                  controller.avatarUrl.value);

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 36.r,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    backgroundImage: hasUrl
                                        ? NetworkImage(fullUrl)
                                            as ImageProvider
                                        : AssetImage(ImagePaths.profileIcon),
                                    onBackgroundImageError: hasUrl
                                        ? (_, _) {
                                            // Fallback handled gracefully
                                          }
                                        : null,
                                  ),
                                  if (controller.isUploadingImage.value)
                                    Container(
                                      width: 72.r,
                                      height: 72.r,
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(5.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 14.sp,
                                color: const Color(0xFF1550A6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    controller.name.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 19.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
                                    'MENTAL HEALTH',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              controller.email.value,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            // ID chip + QR pill + Scan pill (Overflow-safe)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => controller.copyAssignedNumber(),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ID: #${controller.assignedNumber.value}',
                                          style: GoogleFonts.sourceCodePro(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Icon(
                                          Icons.copy_rounded,
                                          size: 11.sp,
                                          color: Colors.white.withValues(alpha: 0.65),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap: () => controller.openDoctorQrCard(initialTabIndex: 0),
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
                            SizedBox(height: 5.h),
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
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: controller.openQrScanner,
                      child: Container(
                        width: 40.w,
                        height: 40.w,
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
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title Section
              Padding(
                padding: EdgeInsets.only(
                  left: 24.w,
                  right: 24.w,
                  top: 24.h,
                  bottom: 12.h,
                ),
                child: Text(
                  'Account & Settings',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),

              // Option list
              _buildOptionItem(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                onTap: () => Get.toNamed(AppRoutes.doctorPersonalInfo),
              ),
              _buildOptionItem(
                icon: Icons.qr_code_2_rounded,
                title: 'Credential QR Code',
                onTap: () => controller.openDoctorQrCard(),
              ),
              _buildOptionItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => Get.toNamed(AppRoutes.doctorSettings),
              ),
              _buildOptionItem(
                icon: Icons.videocam_outlined,
                title: 'History & Recordings',
                onTap: () => Get.toNamed(AppRoutes.doctorHistory),
              ),
              _buildOptionItem(
                icon: Icons.hexagon_outlined,
                title: 'Referral For Points',
                onTap: () => Get.toNamed(AppRoutes.referral),
              ),
              _buildOptionItem(
                icon: Icons.card_giftcard_outlined,
                title: 'Gift Plan',
                onTap: () => Get.toNamed(AppRoutes.giftingHub),
              ),
              _buildOptionItem(
                icon: Icons.sync_rounded,
                title: 'Dispatch Resources',
                onTap: () => Get.toNamed(AppRoutes.doctorDispatch),
              ),
              _buildOptionItem(
                icon: Icons.monetization_on_outlined,
                title: 'Bail Bondsman Directory',
                onTap: () => controller.showBailBondsmenDirectory(),
              ),
              _buildOptionItem(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                isDestructive: true,
                onTap: () => controller.confirmLogout(),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
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
        : const Color(0xFF4A729F);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0x04000000),
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
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w500,
                  color: itemColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF94A3B8),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
