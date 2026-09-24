import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/core/widgets/custom_back_button.dart';
import 'package:gsabino365/module/shared/otp_verification/controller/otp_verification_controller.dart';

class OtpVerificationView extends GetView<OtpVerificationController> {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 55.w,
        leading: const Center(
          child: CustomBackButton(
            containerSize: 36,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SVG illustration at top
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SvgPicture.asset(
                    'assets/images/Enter OTP-amico (1) 1.svg',
                    height: 240.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // White Container at the bottom
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Verify Your Account',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A192F),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Subtitle
                  Text(
                    controller.email.isNotEmpty
                        ? 'Enter the 4-digit verification code sent to\n${controller.email} to confirm your account.'
                        : 'Enter the 4-digit verification code sent to\nyour email to confirm your account.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5F6E80),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // 4-Digit OTP Input Area (with full native backspace & paste support)
                  SizedBox(
                    height: 64.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Hidden underlying textfield that captures keyboard input, backspaces, and paste
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.0,
                            child: TextField(
                              controller: controller.otpController,
                              focusNode: controller.otpFocusNode,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: (value) {
                                if (value.length == 4) {
                                  controller.verifyOtp();
                                }
                              },
                            ),
                          ),
                        ),
                        // 4 Visual Boxes
                        GestureDetector(
                          onTap: () => controller.otpFocusNode.requestFocus(),
                          behavior: HitTestBehavior.opaque,
                          child: Obx(() {
                            final code = controller.otpCode.value;
                            final isFocused = controller.isOtpFocused.value;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) {
                                final hasValue = index < code.length;
                                final char = hasValue ? code[index] : '';
                                final isCurrent = isFocused &&
                                    (code.length == index ||
                                        (code.length == 4 && index == 3));

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 62.w,
                                  height: 64.h,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: hasValue
                                        ? const Color(0xFFE8EEF8)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isCurrent
                                          ? const Color(0xFF1550A6)
                                          : (hasValue
                                              ? const Color(0xFFBDD2F0)
                                              : const Color(0xFFCBD5E1)),
                                      width: isCurrent ? 2.0 : 1.2,
                                    ),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF1550A6)
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    char,
                                    style: GoogleFonts.inter(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1550A6),
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                  // Resend Timer text
                  Obx(
                    () => controller.timerSeconds.value > 0
                        ? Text(
                            'Resend In ${controller.formattedTimer}',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5F6E80),
                            ),
                          )
                        : GestureDetector(
                            onTap: controller.resendOtp,
                            child: Text(
                              'Resend OTP Code',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1550A6),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: 32.h),
                  // Continue Button
                  Obx(
                    () => CustomButton(
                      text: 'Continue',
                      isLoading: controller.isLoading.value,
                      backgroundColor: const Color(0xFF1550A6),
                      borderRadius: 30,
                      height: 56.h,
                      onPressed: controller.verifyOtp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
