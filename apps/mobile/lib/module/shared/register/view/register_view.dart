import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/core/widgets/custom_back_button.dart';
import 'package:gsabino365/module/shared/register/controller/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 55.w,
        leading: const Center(child: CustomBackButton(containerSize: 36)),
        title: Text(
          'Register',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1550A6),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20.h),
                    
                    // Title "Join us as..."
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            'Join us as...',
                            style: GoogleFonts.inter(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          // Subtitle
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'Select the role that best describes you to get started.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5F6E80),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32.h),

                    // Roles List
                    _buildRoleCard(
                      UserRole.citizen,
                      'Citizen',
                      'Access secure services and manage your personal credentials.',
                      hasSubOptions: true,
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildRoleCard(
                      UserRole.attorney,
                      'Attorney',
                      'Deliver expert services and handle client identity verifications.',
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildRoleCard(
                      UserRole.mentalHealth,
                      'Mental Health Professional',
                      'Oversee team workflows and generate high-level security audits.',
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildRoleCard(
                      UserRole.police,
                      'Police',
                      'Configure global system parameters and manage user permissions.',
                    ),
                    SizedBox(height: 16.h),
                    
                    _buildRoleCard(
                      UserRole.bailBondsman,
                      'Bail Bondsman',
                      'Configure global system parameters and manage user permissions.',
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
            
            // Bottom-pinned continue button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Continue',
                backgroundColor: const Color(0xFF1550A6),
                borderRadius: 30,
                height: 56.h,
                onPressed: controller.onContinuePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    UserRole role,
    String title,
    String description, {
    bool hasSubOptions = false,
  }) {
    return Obx(() {
      final isSelected = controller.selectedRole == role;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1550A6) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF1550A6).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 12 : 6,
              offset: isSelected ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => controller.selectRole(role),
            splashColor: const Color(0xFF1550A6).withValues(alpha: 0.04),
            highlightColor: const Color(0xFF1550A6).withValues(alpha: 0.02),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (hasSubOptions) ...[
                        SizedBox(width: 8.w),
                        AnimatedRotation(
                          turns: isSelected ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: isSelected ? const Color(0xFF1550A6) : const Color(0xFF64748B),
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF475569) : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  
                  // Sub-options (e.g. Non-Citizen Support for Citizen card)
                  if (hasSubOptions)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Container(
                        height: isSelected ? null : 0,
                        alignment: Alignment.centerLeft,
                        child: isSelected
                            ? Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  GestureDetector(
                                    onTap: controller.onNonCitizenSupportPressed,
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEBF3FF),
                                        borderRadius: BorderRadius.circular(10.r),
                                        border: Border.all(
                                          color: const Color(0xFF1550A6).withValues(alpha: 0.4),
                                          width: 1.0,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Non-Citizen Support',
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1550A6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
