import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/Simplification.svg',
              width: 120.w,
              height: 120.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 24.h),
            // Title text
            Text(
              'Your Password Has Been Changed Successfully',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A192F),
                height: 1.4,
              ),
            ),
            SizedBox(height: 32.h),
            // Back to Log In Button
            CustomButton(
              text: 'Back To Log In',
              backgroundColor: const Color(0xFF1550A6),
              borderRadius: 30,
              height: 56.h,
              onPressed: () {
                Get.offAllNamed(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
