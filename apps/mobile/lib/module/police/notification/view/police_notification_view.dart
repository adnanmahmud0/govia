import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/common_notification_card.dart';
import 'package:gsabino365/module/police/notification/controller/police_notification_controller.dart';

class PoliceNotificationView extends GetView<PoliceNotificationController> {
  const PoliceNotificationView({super.key});

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
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.inter(
                            fontSize: 26.sp,
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
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (unread > 0) ...[
                                      Container(
                                        width: 8.w,
                                        height: 8.w,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF5252),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                    ],
                                    Text(
                                      '$unread Unread',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF1550A6),
                                        fontSize: 12.sp,
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
                                  child: Icon(
                                    Icons.done_all_rounded,
                                    color: const Color(0xFF1550A6),
                                    size: 20.sp,
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Stay up to date with departmental alerts and dispatches',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF7A8A9A),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1550A6)),
                    );
                  }

                  if (controller.notifications.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => controller.fetchNotifications(),
                      color: const Color(0xFF1550A6),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: 100.h),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 48.sp,
                                  color: const Color(0xFF90A0B3),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No notifications yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
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
                    onRefresh: () => controller.fetchNotifications(),
                    color: const Color(0xFF1550A6),
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.notifications.length,
                      separatorBuilder: (context, index) => SizedBox(height: 2.h),
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

