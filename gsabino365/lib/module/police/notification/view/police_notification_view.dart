import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/police/notification/controller/police_notification_controller.dart';

class PoliceNotificationView extends GetView<PoliceNotificationController> {
  const PoliceNotificationView({super.key});

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}';
  }

  Color _getBadgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'dispatch':
        return const Color(0xFF1550A6);
      case 'registry':
        return const Color(0xFF2E7D8C);
      case 'system':
      case 'security':
        return const Color(0xFF2E7D32);
      case 'legal':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF1550A6);
    }
  }

  String _getInitials(String title) {
    if (title.isEmpty) return 'PD';
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return title.substring(0, title.length.clamp(1, 2)).toUpperCase();
  }

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
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.notifications.length,
                      itemBuilder: (context, index) {
                        final notif = controller.notifications[index];
                        final isUnread = !notif.isRead;
                        final color = _getBadgeColor(notif.type);
                        final initials = _getInitials(notif.title);

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                            child: InkWell(
                              onTap: () => controller.markAsRead(notif),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: isUnread
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isUnread
                                        ? const Color(0xFF1550A6).withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isUnread
                                          ? const Color(0xFF1550A6).withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.03),
                                      blurRadius: isUnread ? 12 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 48.w,
                                          height: 48.w,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: color.withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              initials,
                                              style: GoogleFonts.inter(
                                                color: color,
                                                fontSize: initials.length > 2 ? 11.sp : 15.sp,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isUnread)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              width: 12.w,
                                              height: 12.w,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF5252),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15.sp,
                                                    fontWeight: isUnread
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                    color: const Color(0xFF0A192F),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                _formatRelativeTime(notif.createdAt),
                                                style: GoogleFonts.inter(
                                                  fontSize: 11.sp,
                                                  color: const Color(0xFF90A0B3),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5.h),
                                          Text(
                                            notif.subtitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              color: isUnread
                                                  ? const Color(0xFF3A4A5C)
                                                  : const Color(0xFF7A8A9A),
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
}

