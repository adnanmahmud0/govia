import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/citizen/encounter_history/controller/encounter_history_controller.dart';

class EncounterHistoryView extends GetView<EncounterHistoryController> {
  const EncounterHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Encounter History',
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

              // Filter Pills Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() => Row(
                    children: [
                      _buildFilterPill('All'),
                      SizedBox(width: 12.w),
                      _buildFilterPill('This Month'),
                      SizedBox(width: 12.w),
                      _buildFilterPill('This Year'),
                    ],
                  )),
                ),
              ),

              SizedBox(height: 16.h),

              // Date section header & list
              Expanded(
                child: Obx(() {
                  if (controller.filteredEncounters.isEmpty) {
                    return Center(
                      child: Text(
                        'No encounters found.',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: controller.filteredEncounters.length,
                    itemBuilder: (context, index) {
                      final item = controller.filteredEncounters[index];
                      
                      // Check if we need to draw date subtitle "April 2026"
                      // For simplicity in static design, we draw it before the first element
                      final showDateHeader = index == 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            Text(
                              'April 2026',
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            SizedBox(height: 16.h),
                          ],
                          _buildEncounterCard(item),
                          SizedBox(height: 20.h),
                        ],
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

  Widget _buildFilterPill(String name) {
    final isActive = controller.activeFilter.value == name;
    return GestureDetector(
      onTap: () => controller.applyFilter(name),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1550A6) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isActive ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1.w,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF1550A6).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEncounterCard(EncounterModel encounter) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Thumbnail area
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.r),
                  topRight: Radius.circular(15.r),
                ),
                child: Image.network(
                  encounter.imageUrl,
                  height: 160.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160.h,
                      color: const Color(0xFFE2E8F0),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: Color(0xFF1550A6),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160.h,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.white60,
                        size: 32.sp,
                      ),
                    );
                  },
                ),
              ),
              // Duration Badge
              Positioned(
                top: 12.h,
                right: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    encounter.duration,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Text details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  encounter.title,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  encounter.dateTime,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFF1550A6),
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      encounter.locationName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // View Button
                CustomButton(
                  text: 'View',
                  onPressed: () => Get.toNamed(
                    AppRoutes.citizenIncidentLocation,
                    arguments: encounter,
                  ),
                  backgroundColor: const Color(0xFF1550A6),
                  borderRadius: 12,
                  height: 48.h,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
