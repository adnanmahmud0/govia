import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';

/// ===================== PREMIUM ERROR WIDGET =====================
/// A modern error display widget with customizable colors and layout.
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String retryLabel;
  final IconData? retryIcon;
  final Color? color;

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.retryLabel = 'Retry',
    this.retryIcon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // If color is null, use Primary Color
    final themeColor = color ?? Theme.of(context).primaryColor;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with Soft Background
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                color: themeColor,
                size: 64.sp,
              ),
            ),
            SizedBox(height: 24.h),

            // Title
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

            if (title != null) SizedBox(height: 8.h),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            if (onRetry != null) ...[
              SizedBox(height: 32.h),

              // Premium Retry Button
              SizedBox(
                width: 150.w,
                child: CustomButton(
                  text: retryLabel,
                  onPressed: onRetry,
                  icon: Icon(retryIcon ?? Icons.refresh_rounded),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
