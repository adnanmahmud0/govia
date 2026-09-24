import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gsabino365/config/routes/app_pages.dart';

class SubscriptionHelper {
  static void showSubscriptionDialog({
    String? title,
    String? message,
    VoidCallback? onPress,
    String? buttonText,
  }) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Center(
          child: Text(
            title ??   '  Subscription Required',
            style: GoogleFonts.arimo(
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
          ),
        ),
        content: Text(
          message ?? 'Please subscribe to access this feature.',
          textAlign: TextAlign.center,
          style: GoogleFonts.arimo(fontSize: 15.sp),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPress ??
                  () {
                    Get.back();
                    Get.toNamed(AppRoutes.subscription);
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9945FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Text(
                buttonText ?? 'Upgrade Now',
                style: GoogleFonts.arimo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
