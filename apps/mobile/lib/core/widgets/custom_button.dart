import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/themes/app_theme.dart';

/// ===================== CUSTOM BUTTON =====================
/// A full-width elevated button with loading state, customizable colors,
/// border radius, and optional icon support.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Widget? icon;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.icon,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.primaryColor;
    final radius = BorderRadius.circular((borderRadius ?? 12).r);

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: bgColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: radius),
                padding: padding,
              ),
              child: _buildChild(bgColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: textColor ?? Colors.white,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(borderRadius: radius),
                elevation: 4,
                shadowColor: bgColor.withValues(alpha: 0.3),
                padding: padding,
              ),
              child: _buildChild(null),
            ),
    );
  }

  Widget _buildChild(Color? outlineColor) {
    if (isLoading) {
      return SizedBox(
        width: 22.h,
        height: 22.h,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            outlineColor ?? Colors.white,
          ),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: (fontSize ?? 16).sp,
        fontWeight: FontWeight.w600,
        color: outlineColor ?? textColor ?? Colors.white,
      ),
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          SizedBox(width: 8.w),
          textWidget,
        ],
      );
    }

    return textWidget;
  }
}
