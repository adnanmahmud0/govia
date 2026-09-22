import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/location_service.dart';
import 'package:gsabino365/module/police/home/controller/police_home_controller.dart';

class PoliceHomeView extends GetView<PoliceHomeController> {
  const PoliceHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Container
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
                child: Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Profile Image + Officer Details + Actions
                      Row(
                        children: [
                          // Profile Image
                          GestureDetector(
                            onTap: () => controller.openOfficerQrCard(),
                            child: Container(
                              width: 52.r,
                              height: 52.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.w),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26.r),
                                child: controller.avatarUrl.value.isNotEmpty
                                    ? Image.network(
                                        controller.avatarUrl.value,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.white24,
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 26.sp,
                                              ),
                                            ),
                                      )
                                    : Image.asset(
                                        'assets/images/user_avatar.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.white24,
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 26.sp,
                                              ),
                                            ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),

                          // Officer Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.officerName.value,
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
                                  controller.officerTitle.value.isNotEmpty
                                      ? controller.officerTitle.value
                                      : 'Police Officer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                if (controller.department.value.isNotEmpty) ...[
                                  SizedBox(height: 1.h),
                                  Text(
                                    controller.department.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
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
                                onTap: () => controller.openNotifications(),
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
                                        if (controller.unreadNotifications.value > 0)
                                          Positioned(
                                            top: -2.r,
                                            right: -2.r,
                                            child: Container(
                                              padding: EdgeInsets.all(4.r),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${controller.unreadNotifications.value}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 9.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
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
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // Action Bar: BADGE # chip + Show QR Pill + Scan QR Pill (Overflow-safe scroll)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => controller.copyHexId(),
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
                                      'BADGE #${controller.badgeId.value}',
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
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
                              onTap: () => controller.openQrDialog(initialTabIndex: 0),
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
                    ],
                  );
                }),
              ),

              // Cards Body with RefreshIndicator
              RefreshIndicator(
                onRefresh: () => controller.refreshDashboardData(),
                color: const Color(0xFF1550A6),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // LIVE INCIDENT ALERT BANNER (Dynamically shown when active citizen encounters exist)
                      Obx(() {
                        if (controller.liveIncidentsCount.value > 0) {
                          return _buildLiveIncidentAlertBanner();
                        }
                        return const SizedBox.shrink();
                      }),

                      // PRIMARY HERO CARD: Scan Citizen QR to Join Meeting
                      _buildScannerHeroCard(),
                      SizedBox(height: 16.h),

                      // Quick Action Row: Show Officer QR & My Schedule
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.qr_code_2_rounded,
                              title: 'My Officer QR',
                              subtitle: 'Show credential on scene',
                              onTap: () => controller.openOfficerQrCard(),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.calendar_month_rounded,
                              title: 'Duty Schedule',
                              subtitleWidget: Obx(() => Text(
                                controller.upcomingScheduleCount.value > 0
                                    ? '${controller.upcomingScheduleCount.value} session${controller.upcomingScheduleCount.value > 1 ? 's' : ''} scheduled'
                                    : 'View scheduled sessions',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              onTap: () => controller.openSchedule(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Card 2: Legal Assistance Protocol
                      _buildZoomCard(
                        icon: Icons.gavel_rounded,
                        watermark: Icons.shield_outlined,
                        title: 'Legal Assistance Protocol',
                        description:
                            'On-call public defender oversight. Automatically linked when scanning a citizen encounter QR.',
                        buttonText: 'VERIFY CITIZEN ENCOUNTER',
                        onPressed: () => controller.openScanner(),
                      ),
                      SizedBox(height: 20.h),

                      // Card 3: Mental Health Crisis Link
                      _buildZoomCard(
                        icon: Icons.psychology_rounded,
                        watermark: Icons.psychology_outlined,
                        title: 'Crisis & Mental Health Link',
                        description:
                            'Licensed crisis counselors for encounter de-escalation, activated through on-scene citizen verification.',
                        buttonText: 'SCAN CITIZEN QR TO ENGAGE',
                        onPressed: () => controller.openScanner(),
                        secondaryActionText: 'OPEN CRISIS LIVE LINK',
                        onSecondaryAction: () => controller.openCrisisManagement(),
                      ),
                      SizedBox(height: 20.h),

                      // Card 4: GoVia AI
                      _buildGoviaCard(),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildScannerHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5.w),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: const Color(0xFF10B981),
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encounter QR Verification',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'EXCLUSIVE INCIDENT ENTRY',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'Scan a citizen\'s GoVia QR code or bumper sticker on scene. If an active emergency encounter is running, you can immediately join the live incident video room.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () => controller.openScanner(),
              icon: Icon(Icons.center_focus_strong_rounded, size: 20.sp, color: Colors.white),
              label: Text(
                'SCAN CITIZEN QR TO JOIN',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIncidentAlertBanner() {
    return Obx(() {
      final count = controller.liveIncidentsCount.value;
      final firstIncident = controller.activeIncidents.isNotEmpty
          ? controller.activeIncidents.first
          : null;

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'LIVE CITIZEN INCIDENT ($count ACTIVE)',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.warning_amber_rounded, color: Colors.white70, size: 20.sp),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              firstIncident?.topic != null && firstIncident!.topic.isNotEmpty
                  ? firstIncident.topic
                  : 'Active Citizen Incident Encounter',
              style: GoogleFonts.inter(
                fontSize: 15.5.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Caller: ${firstIncident?.callerName ?? "Verified Citizen"} • Direct officer room entry authorized',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            if (firstIncident != null &&
                (firstIncident.latitude != null && firstIncident.longitude != null ||
                    (firstIncident.locationAddress != null &&
                        firstIncident.locationAddress!.isNotEmpty))) ...[
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () {
                  if (firstIncident.latitude != null && firstIncident.longitude != null) {
                    LocationService.openGoogleMaps(
                      latitude: firstIncident.latitude!,
                      longitude: firstIncident.longitude!,
                    );
                  } else if (firstIncident.locationAddress != null) {
                    LocationService.openGoogleMapsByQuery(firstIncident.locationAddress!);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          firstIncident.locationAddress != null &&
                                  firstIncident.locationAddress!.isNotEmpty
                              ? firstIncident.locationAddress!
                              : LocationService.formatCoordinates(
                                  firstIncident.latitude!, firstIncident.longitude!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Google Maps ↗',
                          style: GoogleFonts.inter(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 42.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (firstIncident != null) {
                    controller.joinActiveIncident(firstIncident);
                  } else {
                    controller.openScanner();
                  }
                },
                icon: Icon(Icons.videocam_rounded, size: 18.sp, color: const Color(0xFF991B1B)),
                label: Text(
                  'JOIN LIVE INCIDENT ROOM',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: const Color(0xFF1550A6), size: 20.sp),
                ),
                SizedBox(height: 10.h),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2.h),
                subtitleWidget ??
                    Text(
                      subtitle ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomCard({
    required IconData icon,
    required IconData watermark,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    return Container(
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
      child: Stack(
        children: [
          // Background Watermark Icon (Top-Right)
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: 0.04,
              child: Icon(watermark, size: 72.sp, color: Colors.black),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6), // light pink
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFDC2626), // red
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF114FA8),
                ),
              ),
              SizedBox(height: 8.h),

              // Description
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF114FA8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: Text(buttonText),
                ),
              ),
              if (secondaryActionText != null && onSecondaryAction != null) ...[
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  height: 42.h,
                  child: OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF114FA8),
                      side: const BorderSide(color: Color(0xFF114FA8), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    child: Text(secondaryActionText),
                  ),
                ),
              ],
            ],
          ),
        ],
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
            // GoVia AI rounded logo
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
