import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/services/location_service.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/module/doctore/active_sessions/controller/doctor_active_sessions_controller.dart';

class DoctorActiveSessionsView extends GetView<DoctorActiveSessionsController> {
  const DoctorActiveSessionsView({super.key});

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
                          'Active Crisis Sessions',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              // Active Sessions List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.activeMeetings.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1550A6)),
                    );
                  }

                  final hasLive = controller.activeMeetings.isNotEmpty;

                  return RefreshIndicator(
                    onRefresh: () => controller.fetchActiveSessions(),
                    color: const Color(0xFF1550A6),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 8.h,
                      ),
                      itemCount: hasLive
                          ? controller.activeMeetings.length
                          : controller.defaultMockSessions.length,
                      itemBuilder: (context, index) {
                        if (hasLive) {
                          final meeting = controller.activeMeetings[index];
                          return _buildLiveMeetingCard(meeting);
                        } else {
                          final session = controller.defaultMockSessions[index];
                          return _buildMockSessionCard(session);
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMeetingCard(MeetingModel meeting) {
    final caller = meeting.callerName ?? 'Active Caller';
    final topic = meeting.topic.isNotEmpty
        ? meeting.topic
        : 'Priority 1: Urgent Crisis Intervention';

    return GestureDetector(
      onTap: () => controller.openMeeting(meeting),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFFECDD3),
            width: 1.2.w,
          ),
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
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444),
                  width: 1.5.w,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: const Color(0xFFEF4444),
                  size: 24.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '● LIVE ENCOUNTER',
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Title
                  Text(
                    topic,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1550A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Subtitle
                  Text(
                    'Caller: $caller • Tap to enter consultation room',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Interactive Live Location Chip
                  if (meeting.latitude != null && meeting.longitude != null ||
                      (meeting.locationAddress != null &&
                          meeting.locationAddress!.isNotEmpty)) ...[
                    SizedBox(height: 6.h),
                    GestureDetector(
                      onTap: () {
                        if (meeting.latitude != null && meeting.longitude != null) {
                          LocationService.openGoogleMaps(
                            latitude: meeting.latitude!,
                            longitude: meeting.longitude!,
                          );
                        } else if (meeting.locationAddress != null) {
                          LocationService.openGoogleMapsByQuery(meeting.locationAddress!);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 0.8.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: const Color(0xFF2563EB),
                              size: 13.sp,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                meeting.locationAddress != null &&
                                        meeting.locationAddress!.isNotEmpty
                                    ? meeting.locationAddress!
                                    : LocationService.formatCoordinates(
                                        meeting.latitude!, meeting.longitude!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  color: const Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.open_in_new_rounded,
                              color: const Color(0xFF2563EB),
                              size: 11.5.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFFEF4444),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockSessionCard(Map<String, dynamic> session) {
    return GestureDetector(
      onTap: () => controller.openMockSession(session),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.w,
          ),
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
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.w,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26.r),
                child: Image.asset(
                  session['avatar'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF1550A6),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '● ACTIVE THREAD',
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Title
                  Text(
                    session['title'],
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1550A6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Subtitle
                  Text(
                    '${session['officer']} • ${session['district']}',
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
              color: const Color(0xFFEF4444),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
