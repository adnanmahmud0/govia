import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:gsabino365/data/models/notification_model.dart';

class CommonNotificationCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  final bool isLast;

  const CommonNotificationCard({
    super.key,
    required this.notif,
    required this.onTap,
    this.isLast = false,
  });

  Color _getAccentColor() {
    if (notif.isIncident) return const Color(0xFFDC2626); // Emergency Red
    if (notif.isRecording) return const Color(0xFFE11D48); // Rose
    if (notif.isVault) return const Color(0xFF1550A6); // Govia Blue
    if (notif.isMeeting) return const Color(0xFF059669); // Emerald
    final t = notif.type.toLowerCase();
    if (t == 'duty' || t == 'dispatch') return const Color(0xFFD97706); // Amber
    if (t == 'bail') return const Color(0xFF7C3AED); // Violet
    return const Color(0xFF1550A6);
  }

  IconData _getLeadingIcon() {
    if (notif.isIncident) return Icons.warning_amber_rounded;
    if (notif.isRecording) return Icons.videocam_rounded;
    if (notif.isVault) return Icons.folder_special_rounded;
    if (notif.isMeeting) return Icons.videocam_outlined;
    final t = notif.type.toLowerCase();
    if (t == 'duty') return Icons.assignment_outlined;
    if (t == 'dispatch') return Icons.radar_rounded;
    if (t == 'bail') return Icons.gavel_rounded;
    if (t == 'medical') return Icons.medical_services_outlined;
    return Icons.notifications_none_rounded;
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    final leadingIcon = _getLeadingIcon();
    final isUnread = !notif.isRead;
    final callerName = notif.callerName;
    final location = notif.location;
    final isLive = notif.isLive;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isUnread ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isUnread
                    ? accentColor.withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0),
                width: isUnread ? 1.5.w : 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUnread
                      ? accentColor.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header Row: Icon Avatar, Category Badge, Time, Unread Dot ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Circle
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        leadingIcon,
                        color: accentColor,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Badge Pill
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive || notif.isIncident) ...[
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 5.w),
                          ],
                          Text(
                            notif.badgeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Time string
                    Text(
                      _formatTime(notif.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                        color: isUnread ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                      ),
                    ),

                    if (isUnread) ...[
                      SizedBox(width: 8.w),
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 10.h),

                // ── Title ──
                Text(
                  notif.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5.sp,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),

                SizedBox(height: 5.h),

                // ── Subtitle Description ──
                Text(
                  notif.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),

                // ── Metadata Chips: Caller & Location (Shown for Incidents / Calls) ──
                if ((callerName != null && callerName.isNotEmpty) ||
                    (location != null && location.isNotEmpty)) ...[
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      if (callerName != null && callerName.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline_rounded, size: 12.sp, color: const Color(0xFF475569)),
                              SizedBox(width: 4.w),
                              Text(
                                callerName,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (location != null && location.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_outlined, size: 12.sp, color: const Color(0xFF475569)),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  location,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],

                SizedBox(height: 12.h),

                // ── Action Footer: Clear Prompt to Redirect ──
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        notif.isIncident
                            ? Icons.play_circle_filled_rounded
                            : notif.isVault
                                ? Icons.folder_open_rounded
                                : notif.isMeeting
                                    ? Icons.video_call_rounded
                                    : Icons.arrow_forward_rounded,
                        size: 15.sp,
                        color: accentColor,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          notif.actionLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16.sp,
                        color: accentColor,
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
  }
}
