import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/attorney/active_requests/controller/attorney_active_requests_controller.dart';

class AttorneyActiveRequestsView
    extends GetView<AttorneyActiveRequestsController> {
  const AttorneyActiveRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Back button App Bar
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
                          'Active Requests',
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
                    // Empty widget to balance back button
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              // Title Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Obx(() {
                  final count = controller.activeRequests.length;
                  final countStr = count < 10 ? '0$count' : '$count';
                  return Text(
                    'Active Requests ($countStr)',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1550A6),
                    ),
                  );
                }),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  'Personnel currently requesting verification support.',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Active Requests List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.activeRequests.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1550A6),
                      ),
                    );
                  }

                  if (controller.activeRequests.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => controller.loadActiveRequests(),
                      color: const Color(0xFF1550A6),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: 80.h),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80.r,
                                  height: 80.r,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.campaign_outlined,
                                    size: 40.sp,
                                    color: const Color(0xFF1550A6),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  'No Live Incident Requests',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                                  child: Text(
                                    'There are currently no active emergency or consultation requests in your area.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.loadActiveRequests(),
                    color: const Color(0xFF1550A6),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 8.h,
                      ),
                      itemCount: controller.activeRequests.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final item = controller.activeRequests[index];
                        return Container(
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
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Avatar, Name/Location, and Join button
                            Row(
                              children: [
                                // Avatar image representing the requesting personnel
                                Container(
                                  width: 48.r,
                                  height: 48.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24.r),
                                    child: (item['avatar'] != null &&
                                            item['avatar'].toString().startsWith('http'))
                                        ? Image.network(
                                            item['avatar'] as String,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildFallbackAvatar(),
                                          )
                                        : _buildFallbackAvatar(),
                                  ),
                                ),
                                SizedBox(width: 14.w),

                                // Name & Location
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['name'] as String,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          if (item['shortId'] != null &&
                                              item['shortId'] != 'N/A') ...[
                                            SizedBox(width: 4.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(4.r),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Text(
                                                '#${item['shortId']}',
                                                style: GoogleFonts.sourceCodePro(
                                                  fontSize: 10.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF1D4ED8),
                                                ),
                                              ),
                                            ),
                                          ],
                                          SizedBox(width: 6.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              item['state'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                        ),
                                      SizedBox(height: 5.h),
                                      GestureDetector(
                                        onTap: () => controller.openGoogleMaps(item),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 3.5.h,
                                          ),
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
                                                  item['location'] as String,
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
                                  ),
                                ),

                                // Join Button
                                Obx(() {
                                  final isThisJoining = controller.isJoining.value &&
                                      controller.joiningMeetingId.value == item['id'];
                                  return SizedBox(
                                    width: 76.w,
                                    height: 38.h,
                                    child: ElevatedButton(
                                      onPressed: isThisJoining
                                          ? null
                                          : () => controller.joinRequest(
                                                item,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1550A6),
                                        padding: EdgeInsets.zero,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                      ),
                                      child: isThisJoining
                                          ? SizedBox(
                                              width: 16.r,
                                              height: 16.r,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Join',
                                              style: GoogleFonts.inter(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  );
                                }),
                              ],
                            ),

                            SizedBox(height: 12.h),

                            // Waiting Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.r,
                                    height: 6.r,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Waiting at ${item['waitingTime']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 12.h),

                            // Code Display Pill Box
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['code'] as String,
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => controller.copyCode(
                                      item['code'] as String,
                                    ),
                                    child: Icon(
                                      Icons.content_copy_rounded,
                                      color: const Color(0xFF1550A6),
                                      size: 18.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
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

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFF1550A6),
      child: const Icon(
        Icons.person,
        color: Colors.white,
      ),
    );
  }
}
