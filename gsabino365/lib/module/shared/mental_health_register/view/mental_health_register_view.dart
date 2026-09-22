import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/core/widgets/custom_back_button.dart';
import 'package:gsabino365/core/widgets/custom_text_field.dart';
import 'package:gsabino365/module/shared/mental_health_register/controller/mental_health_register_controller.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class MentalHealthRegisterView extends GetView<MentalHealthRegisterController> {
  const MentalHealthRegisterView({super.key});

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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),
                
                // Title
                Center(
                  child: Text(
                    'Mental Health Professional',
                    style: GoogleFonts.inter(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0A192F),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Subtitle
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'Use proper information to continue.',
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
                SizedBox(height: 36.h),

                // Full Name
                CustomTextField(
                  label: 'Full Name',
                  hintText: 'Enter Your Name',
                  controller: controller.nameController,
                ),
                SizedBox(height: 20.h),

                // Email
                CustomTextField(
                  label: 'Email',
                  hintText: 'Enter Your Email',
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20.h),

                // Languages Spoken
                CustomTextField(
                  label: 'Languages Spoken',
                  hintText: 'e.g. English, Spanish',
                  controller: controller.languagesController,
                ),
                SizedBox(height: 20.h),

                // Password
                Obx(
                  () => CustomTextField(
                    label: 'Password',
                    hintText: 'Type Your Password',
                    controller: controller.passwordController,
                    obscureText: controller.isPasswordObscured.value,
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
                SizedBox(height: 20.h),

                // Role (Dropdown)
                _buildFieldLabel('Role'),
                Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: controller.selectedRole,
                    hint: Text(
                      'Select',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF90A0B3),
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: const Color(0xFF1550A6),
                      size: 24.sp,
                    ),
                    dropdownColor: const Color(0xFFE8EEF8),
                    decoration: _buildInputDecoration(hintText: 'Select'),
                    items: controller.rolesList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            color: const Color(0xFF0A192F),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: controller.setSelectedRole,
                  ),
                ),
                SizedBox(height: 20.h),

                // Medical License Number
                CustomTextField(
                  label: 'Medical License Number',
                  hintText: 'Enter Medical License Number',
                  controller: controller.licenseNumberController,
                ),
                SizedBox(height: 20.h),

                // Specialization
                CustomTextField(
                  label: 'Specialization',
                  hintText: 'Enter Your Specialization',
                  controller: controller.specializationController,
                ),
                SizedBox(height: 20.h),

                // Company Name
                CustomTextField(
                  label: 'Company Name',
                  hintText: 'Enter Your Company Name',
                  controller: controller.companyNameController,
                ),
                SizedBox(height: 20.h),

                // Business Address
                CustomTextField(
                  label: 'Business Address',
                  hintText: 'Enter Your Business Address',
                  controller: controller.addressController,
                ),
                SizedBox(height: 40.h),

                // Sign Up Button
                Obx(
                  () => CustomButton(
                    text: 'Sign Up',
                    isLoading: controller.isLoading.value,
                    backgroundColor: const Color(0xFF1550A6),
                    borderRadius: 30,
                    height: 56.h,
                    onPressed: controller.register,
                  ),
                ),
                SizedBox(height: 24.h),

                // Already have an account? Login
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.offAllNamed(AppRoutes.login);
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5F6E80),
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1550A6),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
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
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
          children: const [
            TextSpan(
              text: '*',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
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
