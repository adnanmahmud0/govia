import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/common_notification_card.dart';
import 'package:gsabino365/module/bail_bondsman/notification/controller/bail_bondsman_notification_controller.dart';

class BailBondsmanNotificationView extends GetView<BailBondsmanNotificationController> {
  const BailBondsmanNotificationView({super.key});

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
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A192F),
                          ),
                        ),
                        Obx(() {
                          final count = controller.unreadCount;
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1550A6).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: count > 0 ? const Color(0xFFFF5252) : const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  count > 0 ? '$count Unread' : 'All Caught Up',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1550A6),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Stay up to date with your latest bond alerts',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF7A8A9A),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Filter chips & Mark All as Read Row
                    Row(
                      children: [
                        _buildFilterChip('All'),
                        SizedBox(width: 8.w),
                        _buildFilterChip('Unread'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => controller.markAllAsRead(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Mark all read',
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1550A6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1550A6)),
                      ),
                    );
                  }

                  final list = controller.filteredNotifications;

                  if (list.isEmpty) {
                    return RefreshIndicator(
                      color: const Color(0xFF1550A6),
                      onRefresh: () => controller.fetchNotifications(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 60.h),
                        children: [
                          Center(
                            child: Container(
                              width: 64.r,
                              height: 64.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0E7FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                color: const Color(0xFF1550A6),
                                size: 32.sp,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No Notifications Found',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'You do not have any notifications matching this filter.',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF1550A6),
                    onRefresh: () => controller.fetchNotifications(),
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      itemCount: list.length,
                      separatorBuilder: (context, index) => SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final notif = list[index];
                        final isLast = index == list.length - 1;
                        return CommonNotificationCard(
                          notif: notif,
                          isLast: isLast,
                          onTap: () => controller.onNotificationTapped(notif),
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

  Widget _buildFilterChip(String label) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == label;
      return GestureDetector(
        onTap: () => controller.selectedFilter.value = label,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1550A6) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? const Color(0xFF1550A6) : const Color(0xFFCBD5E1),
              width: 1.w,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      );
    });
  }
}
