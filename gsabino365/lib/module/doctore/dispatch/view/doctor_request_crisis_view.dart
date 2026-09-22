import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorRequestCrisisView extends StatelessWidget {
  const DoctorRequestCrisisView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 50.w,
          leading: Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: GestureDetector(
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
                  size: 16.sp,
                ),
              ),
            ),
          ),
          title: Text(
            'Mobile Crisis Team',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1550A6),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                // Blue Info Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          'Need Immediate Mental Health Support?',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Section Title
                Text(
                  'Available Crisis Professionals',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),

                // Professionals List
                _buildProfessionalCard(
                  id: '101',
                  license: 'PSY-887213',
                  name: 'Dr. Sarah Chen',
                  role: 'Psychiatrist',
                  avatar: 'assets/images/doctor_avatar.png',
                  isOnline: true,
                ),
                SizedBox(height: 16.h),

                _buildProfessionalCard(
                  id: '102',
                  license: 'THR-992182',
                  name: 'Marcus Thorne',
                  role: 'Therapist',
                  avatar: 'assets/images/businessman_avatar.png',
                  isOnline: true,
                ),
                SizedBox(height: 16.h),

                _buildProfessionalCard(
                  id: '103',
                  license: 'CNS-441289',
                  name: 'Elena Rodriguez',
                  role: 'Counselor',
                  avatar: 'assets/images/user_avatar.png',
                  isOnline: false,
                  rating: '4.7 rating',
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalCard({
    required String id,
    required String license,
    required String name,
    required String role,
    required String avatar,
    required bool isOnline,
    String? rating,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0x02000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Online indicator dot
              Stack(
                children: [
                  Container(
                    width: 56.r,
                    height: 56.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
                      child: Image.asset(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1550A6),
                          child: Icon(Icons.person, color: Colors.white, size: 24.sp),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2.r,
                    right: 2.r,
                    child: Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF3CD278) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.w),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      role,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'ID: $id  |  Lic: $license',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF1550A6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (rating != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: const Color(0xFFA855F7), size: 14.sp),
                          SizedBox(width: 4.w),
                          Text(
                            rating,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFFA855F7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '•  Offline',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Call Button
          GestureDetector(
            onTap: isOnline
                ? () {
                    Get.snackbar(
                      'Emergency Call',
                      'Initiating voice call to $name...',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF1550A6),
                      colorText: Colors.white,
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFF1550A6) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8.r),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_in_talk_rounded,
                    color: isOnline ? Colors.white : const Color(0xFF94A3B8),
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Call',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isOnline ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
