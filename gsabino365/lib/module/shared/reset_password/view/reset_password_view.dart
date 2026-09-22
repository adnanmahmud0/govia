import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/core/widgets/custom_back_button.dart';
import 'package:gsabino365/module/shared/reset_password/controller/reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 55.w,
        leading: const Center(child: CustomBackButton(containerSize: 36)),
        centerTitle: true,
        title: Text(
          'Create A New Password',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1550A6),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Center the SVG illustration in the remaining top space
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SvgPicture.asset(
                    'assets/images/creat new password .svg',
                    height: 200.h,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle
                    Center(
                      child: Text(
                        "Please Choose A New Password For Your Account. Make Sure It's Secure And Easy For You To Remember.Your Password Must Be At Least 8 Characters Long, And Include A Mix Of Letters, Numbers, And Symbols.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5F6E80),
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // New Password Field
                    _buildFieldLabel('New Password'),
                    Obx(
                      () => TextFormField(
                        controller: controller.passwordController,
                        obscureText: controller.isPasswordObscured.value,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0A192F),
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Type Your Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordObscured.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF1550A6),
                              size: 20.sp,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Confirm New Password Field
                    _buildFieldLabel('Confirm New Password'),
                    Obx(
                      () => TextFormField(
                        controller: controller.confirmPasswordController,
                        obscureText: controller.isConfirmPasswordObscured.value,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0A192F),
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Type Your Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isConfirmPasswordObscured.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF1550A6),
                              size: 20.sp,
                            ),
                            onPressed:
                                controller.toggleConfirmPasswordVisibility,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Confirm Button
                    Obx(
                      () => CustomButton(
                        text: 'Confirm',
                        isLoading: controller.isLoading.value,
                        backgroundColor: const Color(0xFF1550A6),
                        borderRadius: 30,
                        height: 56.h,
                        onPressed: controller.resetPassword,
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: const BorderSide(color: Color(0xFFBDD2F0), width: 1.0),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF90A0B3),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFE8EEF8),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
