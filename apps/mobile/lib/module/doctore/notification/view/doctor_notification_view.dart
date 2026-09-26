import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/common_notification_card.dart';
import 'package:gsabino365/module/doctore/notification/controller/doctor_notification_controller.dart';

class DoctorNotificationView extends GetView<DoctorNotificationController> {
  const DoctorNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.inter(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A192F),
                          ),
                        ),
                        Obx(() {
                          final unread = controller.unreadCount;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1550A6)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7.w,
                                      height: 7.w,
                                      decoration: BoxDecoration(
                                        color: unread > 0
                                            ? const Color(0xFFFF5252)
                                            : const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      unread > 0
                                          ? '$unread Unread'
                                          : 'All caught up',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF1550A6),
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unread > 0) ...[
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () => controller.markAllAsRead(),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      'Mark Read',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1550A6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Stay up to date with clinical updates and triage alerts',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF7A8A9A),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1550A6),
                      ),
                    );
                  }

                  if (controller.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 56.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No notifications at this time',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.fetchNotifications(),
                    color: const Color(0xFF1550A6),
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 4.h,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      itemCount: controller.notifications.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final notif = controller.notifications[index];
                        return CommonNotificationCard(
                          notif: notif,
                          onTap: () => controller.onNotificationTapped(notif),
                          isLast: index == controller.notifications.length - 1,
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
}
