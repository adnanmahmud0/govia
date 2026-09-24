import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/doctore/home/controller/doctor_home_controller.dart';

class DoctorHomeView extends GetView<DoctorHomeController> {
  const DoctorHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => controller.refreshDashboardData(),
            color: const Color(0xFF1550A6),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Curved Blue Header)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF114FA8),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Row: Avatar + Name & Role + Top Right Quick Actions
                        Row(
                          children: [
                            // Doctor Avatar
                            GestureDetector(
                              onTap: () => controller.openDoctorQrCard(),
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
                                    final avatar = controller.avatarUrl.value;
                                    if (avatar.isNotEmpty) {
                                      return Image.network(
                                        avatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildAvatarFallback(),
                                      );
                                    }
                                    return Image.asset(
                                      'assets/images/doctor_avatar.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildAvatarFallback(),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),

                            // Doctor Name & Role
                            Expanded(
                              child: Obx(
                                () => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      controller.doctorName.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Role: ${controller.doctorRole.value}',
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
                                  onTap: () => controller.openNotifications(),
                                  child: Obx(() {
                                    final unread = controller.unreadNotifications.value;
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
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
                                              Icons.notifications_none_rounded,
                                              color: Colors.white,
                                              size: 23.sp,
                                            ),
                                          ),
                                        ),
                                        if (unread > 0)
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
                                                unread > 9 ? '9+' : '$unread',
                                                style: GoogleFonts.inter(
                                                  fontSize: 9.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 12.h),

                        // Action Bar: ID Chip + Show QR Card + Scan QR (Overflow-safe scroll)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Obx(
                            () => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => controller.copyAssignedNumber(),
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
                                          'ID: #${controller.assignedNumber.value}',
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
                                  onTap: () => controller.openDoctorQrCard(initialTabIndex: 0),
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
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Main Content Body
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Real-time Monitor Card
                        Obx(() {
                          final count = controller.liveCrisisCount.value;
                          final hasActive = controller.activeCrisisMeetings.isNotEmpty;
                          final topMeeting = hasActive
                              ? controller.activeCrisisMeetings.first
                              : null;

                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: count > 0
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFE2E8F0),
                                width: 1.5.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card Header: Monitor title & Active Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'REAL-TIME MONITOR',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: count > 0
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6.r,
                                            height: 6.r,
                                            decoration: BoxDecoration(
                                              color: count > 0
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF16A34A),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            count > 0 ? '$count ACTIVE' : 'ALL CLEAR',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w800,
                                              color: count > 0
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF16A34A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),

                                // Headline
                                Text(
                                  'Live Crisis Calls',
                                  style: GoogleFonts.inter(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 12.h),

                                // Dynamic call card or calm state
                                if (hasActive && topMeeting != null) ...[
                                  GestureDetector(
                                    onTap: () =>
                                        controller.joinActiveCrisis(topMeeting),
                                    child: Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(
                                          color: const Color(0xFFFECDD3),
                                          width: 1.w,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8.r),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFEE2E2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.warning_amber_rounded,
                                              color: const Color(0xFFEF4444),
                                              size: 20.sp,
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  topMeeting.topic.isNotEmpty
                                                      ? topMeeting.topic
                                                      : 'Priority 1: Active Crisis Incident',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  topMeeting.callerName != null
                                                      ? 'Caller: ${topMeeting.callerName} • Tap to enter room'
                                                      : 'Responder unit active • Tap to join live room',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xFF64748B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              'Join',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: EdgeInsets.all(14.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1.w,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.r),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDCFCE7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.shield_outlined,
                                            color: const Color(0xFF16A34A),
                                            size: 20.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Crisis Channels Secure',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.5.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                'No active crisis calls requiring immediate intervention.',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11.5.sp,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 16.h),

                                // Bottom Link
                                GestureDetector(
                                  onTap: () => controller.openActiveSessions(),
                                  child: Center(
                                    child: Text(
                                      'View All Active Threads →',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF114FA8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 24.h),

                        // Upcoming Schedule Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Schedule',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => controller.openSchedule(),
                              child: Text(
                                'View All →',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF114FA8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Schedule list (Observable)
                        Obx(() {
                          final upcoming = controller.upcomingMeetingsList;
                          if (upcoming.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.w,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.event_available_rounded,
                                    size: 36.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'No upcoming consultations scheduled',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  GestureDetector(
                                    onTap: () => controller.openSchedule(),
                                    child: Text(
                                      '+ Tap to add appointment',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1550A6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                for (int i = 0; i < upcoming.length; i++)
                                  _buildDynamicScheduleTile(
                                    meeting: upcoming[i],
                                    isLast: i == upcoming.length - 1,
                                  ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 20.h),

                        // GoVia AI Container
                        GestureDetector(
                          onTap: () {
                            Get.toNamed(AppRoutes.attorneyGoviaAi);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              children: [
                                // GoVia AI icon container
                                Container(
                                  width: 32.r,
                                  height: 32.r,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF3B82F6),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.psychology,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GoVia AI Support',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'De-escalation protocols & clinical guidelines',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: const Color(0xFF94A3B8),
                                  size: 14.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: FloatingActionButton(
            onPressed: () {
              Get.toNamed(AppRoutes.attorneyChatList);
            },
            backgroundColor: const Color(0xFF114FA8),
            shape: const CircleBorder(),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
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
        size: 28.sp,
      ),
    );
  }

  Widget _buildDynamicScheduleTile({
    required Map<String, dynamic> meeting,
    required bool isLast,
  }) {
    final topic = meeting['topic']?.toString() ?? 'Clinical Consultation';
    final callerName = meeting['callerName']?.toString() ?? 'Patient';
    final startTimeRaw = meeting['startTime'];
    String formattedTime = 'Upcoming';
    if (startTimeRaw != null) {
      try {
        final dt = DateTime.parse(startTimeRaw.toString()).toLocal();
        formattedTime = DateFormat('EEE, MMM d • h:mm a').format(dt);
      } catch (_) {}
    }

    return Column(
      children: [
        InkWell(
          onTap: () => controller.openSchedule(),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.videocam_outlined,
                    color: const Color(0xFF4F46E5),
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 14.w),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedTime,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$callerName • $topic',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1.h,
            thickness: 1.w,
            color: const Color(0xFFF1F5F9),
            indent: 16.w,
            endIndent: 16.w,
          ),
      ],
    );
  }
}
