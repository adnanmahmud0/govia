import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/constants/image_paths.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/attorney/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/attorney/home/controller/attorney_home_controller.dart';

class AttorneyHomeView extends GetView<AttorneyHomeController> {
  const AttorneyHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Professional Solid Blue Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20.h,
                  bottom: 24.h,
                  left: 24.w,
                  right: 24.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar + Name & Role + Top Right Quick Actions
                    Row(
                      children: [
                        // Profile Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white30,
                              width: 2.w,
                            ),
                          ),
                          child: Obx(() {
                            final avatar = controller.avatarUrl;
                            return CircleAvatar(
                              radius: 26.r,
                              backgroundColor: Colors.white24,
                              backgroundImage: avatar.isNotEmpty
                                  ? NetworkImage(ApiConstants.getFileUrl(avatar)) as ImageProvider
                                  : AssetImage(ImagePaths.profileIcon),
                              onBackgroundImageError: (e, s) {},
                            );
                          }),
                        ),
                        SizedBox(width: 12.w),

                        // Name & Role
                        Expanded(
                          child: Obx(
                            () => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Role: ${controller.userRole}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),

                        // Top Right Actions: QR Scanner & Notification Bell
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: controller.openQrScanner,
                              child: Container(
                                width: 42.r,
                                height: 42.r,
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
                                    size: 21.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {
                                Get.find<AttorneyBottomNavBarController>()
                                    .changeTabIndex(2); // Go to notification tab
                              },
                              child: Container(
                                width: 42.r,
                                height: 42.r,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.w,
                                  ),
                                ),
                                child: Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white,
                                        size: 23.sp,
                                      ),
                                      Obx(() {
                                        final unread = controller.unreadNotificationsCount.value;
                                        if (unread <= 0) return const SizedBox.shrink();
                                        return Positioned(
                                          top: -2.h,
                                          right: -2.w,
                                          child: Container(
                                            padding: EdgeInsets.all(4.r),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unread > 99 ? '99+' : '$unread',
                                              style: GoogleFonts.inter(
                                                fontSize: 9.sp,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // Action Bar: ID Chip + Show QR Pill + Scan QR Pill (Overflow-safe scroll)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Obx(
                        () => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final hexId = controller.shortHexId;
                                Clipboard.setData(ClipboardData(text: hexId));
                                Get.rawSnackbar(
                                  message: 'Copied Short Hex ID: #$hexId',
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 0.8.w,
                                  ),
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
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 11.sp,
                                      color: Colors.white60,
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
                                  horizontal: 8.w,
                                  vertical: 3.h,
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
                                    SizedBox(width: 4.w),
                                    Text(
                                      'QR Card',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5.sp,
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
                    ),

                    SizedBox(height: 20.h),

                    // LIVE INCIDENT Pill
                    Obx(() {
                      final count = controller.liveIncidentsCount.value;
                      return GestureDetector(
                        onTap: () =>
                            Get.toNamed(AppRoutes.attorneyActiveRequests),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: count > 0
                                ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: count > 0
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.25),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7.r,
                                height: 7.r,
                                decoration: BoxDecoration(
                                  color: count > 0
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                count > 0
                                    ? '$count LIVE INCIDENT${count > 1 ? 'S' : ''}'
                                    : 'NO LIVE INCIDENTS',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Home Cards Content
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    // Card 1: LIVE INCIDENTS
                    Obx(
                      () => _buildDashboardCard(
                        title: 'LIVE INCIDENTS',
                        icon: Icons.campaign_outlined,
                        count: '${controller.liveIncidentsCount.value}',
                        subtext: 'Active requests in Ohio area',
                        onTap: () =>
                            Get.toNamed(AppRoutes.attorneyActiveRequests),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Card 2: EVIDENCE VAULT
                    Obx(
                      () => _buildDashboardCard(
                        title: 'EVIDENCE VAULT',
                        icon: Icons.folder_shared_outlined,
                        count: '${controller.evidenceVaultCount.value}',
                        subtext: 'Secured digital case assets',
                        onTap: () =>
                            Get.toNamed(AppRoutes.attorneyEvidenceVault),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Card 3: SCHEDULED CONSULTATIONS
                    Obx(
                      () => _buildDashboardCard(
                        title: 'SCHEDULED CONSULTATIONS',
                        icon: Icons.calendar_month_outlined,
                        count: '${controller.upcomingSupportCount.value}',
                        subtext: 'Upcoming client legal sessions',
                        onTap: () =>
                            Get.find<AttorneyBottomNavBarController>().changeTabIndex(1),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Card 4: GoVia AI
                    _buildDashboardCard(
                      title: 'GOVIA AI',
                      icon: Icons.psychology_outlined,
                      subtext: 'Legal research & AI analysis',
                      onTap: () => Get.toNamed(AppRoutes.attorneyGoviaAi),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Get.toNamed(AppRoutes.attorneyChatList);
          },
          backgroundColor: const Color(0xFF1550A6),
          shape: const CircleBorder(),
          elevation: 3,
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    String? count,
    required String subtext,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Side: Soft blue icon container
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: const Color(0xFF1550A6), size: 22.sp),
            ),
            SizedBox(width: 16.w),

            // Middle: Title & Subtext
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtext,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),

            // Right Side: Count (if available)
            if (count != null) ...[
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(width: 12.w),
            ],

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
