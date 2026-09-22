import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/bail_bondsman/home/controller/bail_bondsman_home_controller.dart';

class BailBondsmanHomeView extends GetView<BailBondsmanHomeController> {
  const BailBondsmanHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: RefreshIndicator(
          color: const Color(0xFF1550A6),
          onRefresh: () => controller.refreshDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            child: Column(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name & Role + Top Right Quick Actions
                      Row(
                        children: [
                          // Profile Avatar (Tap to open QR Card Dialog)
                          GestureDetector(
                            onTap: controller.openQrDialog,
                            child: Container(
                              width: 52.r,
                              height: 52.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.w),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26.r),
                                child: Obx(() {
                                  final avatar = controller.avatarUrl;
                                  if (avatar.isNotEmpty) {
                                    return Image.network(
                                      avatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildFallbackAvatar(),
                                    );
                                  }
                                  return _buildFallbackAvatar();
                                }),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),

                          // Profile Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Obx(
                                  () => Text(
                                    controller.userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 19.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
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
                                onTap: controller.goToNotifications,
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
                                          final count = controller.unreadNotificationsCount.value;
                                          if (count == 0) return const SizedBox.shrink();
                                          return Positioned(
                                            top: -2.r,
                                            right: -2.r,
                                            child: Container(
                                              padding: EdgeInsets.all(4.r),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                count > 9 ? '9+' : '$count',
                                                style: GoogleFonts.inter(
                                                  fontSize: 9.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: controller.copyHexId,
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
                                    Obx(
                                      () => Text(
                                        'ID: #${controller.shortHexId}',
                                        style: GoogleFonts.sourceCodePro(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5.w),
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
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: controller.openQrScanner,
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
                                      Icons.qr_code_scanner_rounded,
                                      size: 13.sp,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Scan QR',
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

                      SizedBox(height: 20.h),

                      // Reactive Incident Pill Tag
                      Obx(() {
                        final count = controller.liveIncidentsCount.value;
                        final hasIncidents = count > 0;
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: hasIncidents
                                ? const Color(0xFFDC2626) // alert red
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: hasIncidents
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: BoxDecoration(
                                  color: hasIncidents ? Colors.white : const Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                hasIncidents
                                    ? '$count LIVE INCIDENT${count > 1 ? 'S' : ''}'
                                    : 'STANDBY • MONITORING AREA',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Main Body Content
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // Card 1: Live Incidents
                      Obx(
                        () => _buildStatusCard(
                          title: 'LIVE INCIDENTS',
                          value: controller.liveIncidentsCount.value.toString(),
                          subtitle: controller.liveIncidentsCount.value == 0
                              ? 'No active verification calls'
                              : '${controller.liveIncidentsCount.value} active citizen alert${controller.liveIncidentsCount.value > 1 ? 's' : ''} waiting',
                          hasBlueDot: true,
                          actionWidget: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: const BoxDecoration(
                              color: Color(0xFF114FA8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                          onTap: controller.goToActiveRequests,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Card 2: Upcoming Schedule
                      Obx(
                        () => _buildStatusCard(
                          title: 'UPCOMING SCHEDULE',
                          value: controller.upcomingScheduleCount.value.toString(),
                          subtitle: controller.upcomingScheduleCount.value == 0
                              ? 'No scheduled consultations today'
                              : '${controller.upcomingScheduleCount.value} scheduled hearing${controller.upcomingScheduleCount.value > 1 ? 's' : ''} & consultation${controller.upcomingScheduleCount.value > 1 ? 's' : ''}',
                          actionWidget: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 1.w,
                              ),
                            ),
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: const Color(0xFF114FA8),
                              size: 20.sp,
                            ),
                          ),
                          onTap: controller.goToSchedule,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Card 3: GoVia AI
                      _buildGoviaCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: FloatingActionButton(
            onPressed: () => Get.toNamed(AppRoutes.attorneyChatList),
            backgroundColor: const Color(0xFF114FA8),
            shape: const CircleBorder(),
            child: Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Image.asset(
      'assets/images/user_avatar.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.white24,
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required String subtitle,
    bool hasBlueDot = false,
    required Widget actionWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(20.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hasBlueDot) ...[
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(
                            color: Color(0xFF114FA8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A729F),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            actionWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildGoviaCard() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.attorneyGoviaAi),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              'GoVia AI',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF114FA8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
