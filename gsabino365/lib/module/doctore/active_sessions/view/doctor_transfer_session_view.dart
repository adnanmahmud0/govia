import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/doctore/active_sessions/controller/doctor_transfer_session_controller.dart';

class DoctorTransferSessionView extends GetView<DoctorTransferSessionController> {
  const DoctorTransferSessionView({super.key});

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
                          'Transfer Session',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w),
                  ],
                ),
              ),

              // Search box
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: const Color(0xFF94A3B8), size: 20.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => controller.updateSearchQuery(val),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search name.',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Professionals list
              Expanded(
                child: Obx(() {
                  final list = controller.filteredProfessionals;
                  return ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final prof = list[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFF93C5FD), width: 1.w),
                        ),
                        child: Row(
                          children: [
                            // Doctor Avatar with active green dot
                            Stack(
                              children: [
                                Container(
                                  width: 52.r,
                                  height: 52.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.w),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26.r),
                                    child: Image.asset(
                                      prof['avatar'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: const Color(0xFF1550A6),
                                        child: Icon(Icons.person, color: Colors.white, size: 24.sp),
                                      ),
                                    ),
                                  ),
                                ),
                                if (prof['isOnline'])
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 14.r,
                                      height: 14.r,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3CD278),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.w),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: 16.w),

                            // Name & role
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prof['name'],
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    prof['role'],
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'ID: ${prof['id']}  |  Lic: ${prof['license']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF1550A6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Join button
                            SizedBox(
                              width: 80.w,
                              height: 36.h,
                              child: ElevatedButton(
                                onPressed: () => controller.joinSession(prof),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1C3D8F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.r),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  prof['id'] == '3' ? 'join' : 'Join',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
