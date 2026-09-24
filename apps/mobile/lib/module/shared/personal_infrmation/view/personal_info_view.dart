import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/shared/personal_infrmation/controller/personal_info_controller.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/module/attorney/profile/controller/attorney_profile_controller.dart';
import 'package:gsabino365/module/citizen/profile/controller/citizen_profile_controller.dart';

class PersonalInfoView extends GetView<PersonalInfoController> {
  const PersonalInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: Column(
          children: [
            // Custom Blue App Bar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
              ),
              padding: EdgeInsets.only(
                left: 16.w,
                right: 24.w,
                top: MediaQuery.of(context).padding.top + 12.h,
                bottom: 24.h,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Personal Information',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Details',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Keep your account information updated to receive proper service notifications.',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Inputs Block
                    _buildInputField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      controller: controller.nameController,
                    ),
                    SizedBox(height: 20.h),

                    _buildInputField(
                      label: 'Email Address',
                      hint: 'Enter your email address',
                      icon: Icons.email_outlined,
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 20.h),

                    _buildInputField(
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      controller: controller.phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20.h),

                    _buildInputField(
                      label: 'Languages Spoken',
                      hint: 'e.g. English, Spanish',
                      icon: Icons.language_rounded,
                      controller: controller.languagesController,
                    ),
                    if (Get.isRegistered<AttorneyProfileController>()) ...[
                      SizedBox(height: 20.h),
                      _buildInputField(
                        label: 'Licensed States to Practice',
                        hint: 'e.g. Nationwide or NY, CA, TX',
                        icon: Icons.gavel_rounded,
                        controller: controller.licensedStatesController,
                      ),
                    ],
                    if (Get.isRegistered<CitizenProfileController>()) ...[
                      SizedBox(height: 24.h),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.preferredProviders),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1550A6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_rounded,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Preferred Attorney & Bail Bondsman',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Manage your legal counsel and bail providers',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: const Color(0xFF1550A6),
                                size: 14.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 40.h),

                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: () => controller.saveChanges(),
                      backgroundColor: const Color(0xFF1550A6),
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
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
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF64748B),
                size: 20.sp,
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
