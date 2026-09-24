import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glassmorphic confirmation dialog for ending a meeting.
class MeetingEndDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirmEnd;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const MeetingEndDialog({
    super.key,
    this.title = 'End Consultation Session?',
    this.message =
        'The live consultation will conclude. Video and audio recordings will be safely archived to your incident vault.',
    this.confirmLabel = 'End Call',
    required this.onConfirmEnd,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  static Future<void> show({
    String title = 'End Consultation Session?',
    String message =
        'The live consultation will conclude. Video and audio recordings will be safely archived to your incident vault.',
    String confirmLabel = 'End Call',
    required VoidCallback onConfirmEnd,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    return Get.dialog<void>(
      MeetingEndDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirmEnd: onConfirmEnd,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Icon Beacon
                Container(
                  width: 58.r,
                  height: 58.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      width: 1.5.w,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.call_end_rounded,
                      color: const Color(0xFFEF4444),
                      size: 28.sp,
                    ),
                  ),
                ),

                SizedBox(height: 18.h),

                // 2. Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 10.h),

                // 3. Description
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 24.h),

                if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        onSecondaryAction!();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: BorderSide(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                          width: 1.2.w,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        secondaryActionLabel!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],

                // 4. Actions
                Row(
                  children: [
                    // Stay Button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFCBD5E1),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.14),
                              width: 1.w,
                            ),
                          ),
                        ),
                        child: Text(
                          'Stay in Call',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // End Call Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          onConfirmEnd();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          shadowColor:
                              const Color(0xFFEF4444).withValues(alpha: 0.5),
                        ),
                        child: Text(
                          confirmLabel,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
