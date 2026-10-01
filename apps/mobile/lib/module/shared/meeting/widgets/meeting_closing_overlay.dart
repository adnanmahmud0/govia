import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MeetingClosingOverlay extends StatelessWidget {
  const MeetingClosingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: PopScope(
        canPop: false,
        child: AbsorbPointer(
          child: ColoredBox(
            color: const Color(0xE6070B14),
            child: Center(
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 34.r,
                        height: 34.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Ending call…',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Closing the secure session safely. Please wait.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
