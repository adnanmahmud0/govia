import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/core/widgets/custom_back_button.dart';
import 'package:gsabino365/module/shared/forgot_password/controller/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 55.w,
        leading: const Center(child: CustomBackButton(containerSize: 36)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top illustration
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SvgPicture.asset(
                    'assets/images/Forgot password-amico 1.svg',
                    height: 220.h,
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        'Forgot Your Password?',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A192F),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Subtitle
                    Center(
                      child: Text(
                        "Enter your account role and email address to receive a verification code.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5F6E80),
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Role Selection
                    _buildFieldLabel('Account Role'),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        initialValue: controller.selectedRole.value,
                        decoration: _buildInputDecoration(hintText: 'Select Role'),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF1550A6),
                          size: 24.sp,
                        ),
                        dropdownColor: Colors.white,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A192F),
                        ),
                        items: controller.availableRoles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              controller.roleLabels[role] ?? role,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0A192F),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: controller.setSelectedRole,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Email Label
                    _buildFieldLabel('Email'),
                    TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!GetUtils.isEmail(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0A192F),
                      ),
                      decoration: _buildInputDecoration(
                        hintText: 'Enter Your Email',
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Send OTP Button
                    Obx(
                      () => CustomButton(
                        text: 'Send OTP Code',
                        isLoading: controller.isLoading.value,
                        backgroundColor: const Color(0xFF1550A6),
                        borderRadius: 30,
                        height: 54.h,
                        onPressed: controller.sendOtpCode,
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
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
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
