import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class RedemptionSuccessDialog extends StatelessWidget {
  final String planTitle;
  final String giverName;
  final VoidCallback onClose;

  const RedemptionSuccessDialog({
    super.key,
    required this.planTitle,
    required this.giverName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration Icon
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1550A6), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 36.sp,
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Title
            Text(
              'Gift Activated! 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),

            SizedBox(height: 8.h),

            // Giver tribute
            Text(
              'You have successfully unlocked $planTitle gifted by $giverName.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5.sp,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),

            SizedBox(height: 20.h),

            // Benefit Highlights Box
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
              ),
              child: Column(
                children: [
                  _buildFeatureRow('Unlimited 24/7 Emergency Encounters'),
                  SizedBox(height: 8.h),
                  _buildFeatureRow('Cloud Video Vault Playback & Evidence'),
                  SizedBox(height: 8.h),
                  _buildFeatureRow('Confidential Medical Telehealth & AI Copilot'),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1550A6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'Start Using Protection',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String title) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          size: 16.sp,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
