import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/bail_bondsman/active_requests/controller/bail_bondsman_active_requests_controller.dart';

class BailBondsmanActiveRequestsView extends GetView<BailBondsmanActiveRequestsController> {
  const BailBondsmanActiveRequestsView({super.key});

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
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
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
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              // Title Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        "Active Requests (${controller.requests.length.toString().padLeft(2, '0')})",
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF114FA8),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Personnel currently requesting bond verification & legal support.',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Scrollable Requests List with Reactive State
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.requests.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1550A6)),
                      ),
                    );
                  }

                  if (controller.requests.isEmpty) {
                    return RefreshIndicator(
                      color: const Color(0xFF1550A6),
                      onRefresh: () => controller.loadActiveRequests(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                        children: [
                          Center(
                            child: Container(
                              width: 80.r,
                              height: 80.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                color: const Color(0xFF1550A6),
                                size: 40.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Active Requests',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'There are currently no active emergency or bail verification calls in your area. You will be alerted when a citizen requests your support.',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF1550A6),
                    onRefresh: () => controller.loadActiveRequests(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                      itemCount: controller.requests.length,
                      separatorBuilder: (context, index) => SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final item = controller.requests[index];
                        final avatarStr = item['avatar'] as String? ?? '';
                        return Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Info Row
                              Row(
                                children: [
                                  Container(
                                    width: 48.r,
                                    height: 48.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.w),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24.r),
                                      child: avatarStr.isNotEmpty
                                          ? Image.network(
                                              avatarStr,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  _buildAvatarFallback(),
                                            )
                                          : _buildAvatarFallback(),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        GestureDetector(
                                          onTap: () => controller.openGoogleMaps(item),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 3.h,
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
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12.sp,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF1D4ED8),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(width: 4.w),
                                                Icon(
                                                  Icons.open_in_new_rounded,
                                                  color: const Color(0xFF2563EB),
                                                  size: 11.sp,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 76.w,
                                    height: 40.h,
                                    child: ElevatedButton(
                                      onPressed: () => controller.joinMeeting(item),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF114FA8),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        textStyle: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      child: const Text('Join'),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12.h),

                              // Waiting time pill
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6.r,
                                      height: 6.r,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF114FA8),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Waiting at ${item['waitingTime']}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF114FA8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 12.h),

                              // Clipboard Code Box
                              GestureDetector(
                                onTap: () => controller.copyToClipboard(item['code'] as String),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        item['code'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.content_copy_rounded,
                                        color: const Color(0xFF114FA8),
                                        size: 16.sp,
                                      ),
                                    ],
                                  ),
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

              // Handoff Call Button (Bottom)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: controller.initiateHandoffCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF114FA8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_call_rounded, size: 22.sp),
                        SizedBox(width: 8.w),
                        const Text('Handoff Call'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Image.asset(
      'assets/images/user_avatar.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: Icon(Icons.person, color: Colors.grey, size: 24.sp),
      ),
    );
  }
}
