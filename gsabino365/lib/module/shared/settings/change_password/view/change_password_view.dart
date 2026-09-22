import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/shared/settings/change_password/controller/change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Light App Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: const Color(0xFF1550A6),
                          size: 18.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Change Password',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                      ),
                    ),
                    // Empty widget to balance back button
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Inputs form
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Your Account',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Enter your current password and your new desired password to update details.',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Current Password
                      Obx(() => _buildPasswordField(
                        label: 'Current Password',
                        hint: 'Enter current password',
                        controller: controller.oldPasswordController,
                        obscureText: !controller.showOldPassword.value,
                        onToggleVisibility: controller.toggleOldPassword,
                      )),
                      SizedBox(height: 20.h),

                      // New Password
                      Obx(() => _buildPasswordField(
                        label: 'New Password',
                        hint: 'Enter new password',
                        controller: controller.newPasswordController,
                        obscureText: !controller.showNewPassword.value,
                        onToggleVisibility: controller.toggleNewPassword,
                      )),
                      SizedBox(height: 20.h),

                      // Confirm Password
                      Obx(() => _buildPasswordField(
                        label: 'Confirm New Password',
                        hint: 'Confirm new password',
                        controller: controller.confirmPasswordController,
                        obscureText: !controller.showConfirmPassword.value,
                        onToggleVisibility: controller.toggleConfirmPassword,
                      )),
                      SizedBox(height: 40.h),

                      // Change Password Button
                      Obx(() => CustomButton(
                        text: 'Update Password',
                        isLoading: controller.isLoading.value,
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.updatePassword(),
                        backgroundColor: const Color(0xFF1550A6),
                        borderRadius: 12,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: const Color(0xFF64748B),
                size: 20.sp,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20.sp,
                ),
                onPressed: onToggleVisibility,
              ),
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        ),
      ],
    );
  }
}
