import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// ===================== CUSTOM APP BAR =====================
/// Factory for creating a consistent AppBar across the app.
class CustomAppBar {
  CustomAppBar._();

  /// Create a styled AppBar with optional leading, actions, and bottom widget
  static AppBar build({
    required String title,
    Widget? leading,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool centerTitle = true,
    Color? backgroundColor,
    double? elevation,
  }) {
    return AppBar(
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0, // Prevents color change on scroll
      surfaceTintColor: Colors.transparent, // Fixes Material 3 tint
      // Remove splash effect from AppBar icons
      iconTheme: const IconThemeData(color: Colors.black87),
      actionsIconTheme: const IconThemeData(color: Colors.black87),

      leading: leading,
      actions: actions,
      bottom: bottom,
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}
