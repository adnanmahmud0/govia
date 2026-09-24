import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/module/attorney/notification/controller/attorney_notification_controller.dart';

class AttorneyNotificationView
    extends GetView<AttorneyNotificationController> {
  const AttorneyNotificationView({super.key});

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
                      'Stay up to date with case updates and court filings',
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
                          SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final notif = controller.notifications[index];
                        return _buildNotifCard(notif);
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

  Widget _buildNotifCard(NotificationModel notif) {
    final isUnread = !notif.isRead;
    final initials = _getInitials(notif.title);
    final color = _getColorForType(notif.type);
    final timeStr = _formatTimeAgo(notif.createdAt);

    return InkWell(
      onTap: () => controller.markAsRead(notif),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isUnread
                ? const Color(0xFF1550A6).withValues(alpha: 0.35)
                : const Color(0xFFE2E8F0),
            width: isUnread ? 1.5.w : 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? const Color(0xFF1550A6).withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Initials Avatar
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notif.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.w400,
                      color: isUnread
                          ? const Color(0xFF334155)
                          : const Color(0xFF64748B),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              SizedBox(width: 8.w),
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1550A6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getInitials(String title) {
    if (title.isEmpty) return 'JD';
    final parts = title.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return title.substring(0, title.length >= 2 ? 2 : title.length).toUpperCase();
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'deadline':
        return const Color(0xFFEF4444);
      case 'case':
      case 'court_case':
        return const Color(0xFF1550A6);
      case 'compliance':
        return const Color(0xFF16A34A);
      case 'document':
      case 'case_file':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF0284C7);
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
