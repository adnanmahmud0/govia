import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/core/widgets/custom_back_button.dart';
import 'package:gsabino365/config/constants/image_paths.dart';
import 'package:gsabino365/module/shared/login/controller/login_controller.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

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
          'Log In',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1550A6),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                // Govia Logo at Top Center
                Center(
                  child: Image.asset(
                    ImagePaths.appLogo,
                    height: 85.h,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 16.h),
                // Subtitle
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'Enter A Valid Username And Password To Continue.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5F6E80),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Email Field
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
                SizedBox(height: 20.h),

                // Password Field
                _buildFieldLabel('Password'),
                Obx(
                  () => TextFormField(
                    controller: controller.passwordController,
                    obscureText: controller.isPasswordObscured.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
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
                SizedBox(height: 10.h),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.forgotPassword);
                    },
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1550A6),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                // Log In Button
                Obx(
                  () => CustomButton(
                    text: 'Log In',
                    isLoading: controller.isLoading.value,
                    backgroundColor: const Color(0xFF1550A6),
                    borderRadius: 30,
                    height: 56.h,
                    onPressed: controller.onLoginPressed,
                  ),
                ),
                SizedBox(height: 16.h),

                // Quick Demo Accounts Selector (Multi-Role)
                Obx(
                  () => Center(
                    child: OutlinedButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.showDemoAccountsBottomSheet(),
                      icon: const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF1550A6)),
                      label: Text(
                        '⚡ Quick Demo Accounts (Multi-Role)',
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1550A6),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBDD2F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                        backgroundColor: const Color(0xFFEFF6FF),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Sign Up Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.register);
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't Have An Account? ",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5F6E80),
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1550A6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
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
