import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/attorney/subpoena_request/controller/attorney_subpoena_request_controller.dart';

class AttorneySubpoenaRequestView extends GetView<AttorneySubpoenaRequestController> {
  const AttorneySubpoenaRequestView({super.key});

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
                          'Subpoena Request',
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

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle
                      Text(
                        'Generate and submit a digitally signed subpoena request',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Card 1: Court, Agency, Incident ID
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Court / Jurisdiction label
                            Row(
                              children: [
                                Text(
                                  'Court / Jurisdiction',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: const Color(0xFF64748B),
                                  size: 14.sp,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Obx(() => Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: controller.selectedCourt.value,
                                  items: controller.courts
                                      .map((court) => DropdownMenuItem(
                                            value: court,
                                            child: Text(
                                              court,
                                              style: GoogleFonts.inter(
                                                fontSize: 15.sp,
                                                color: const Color(0xFF0F172A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      controller.selectedCourt.value = val;
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF64748B),
                                  ),
                                  isExpanded: true,
                                ),
                              ),
                            )),
                            SizedBox(height: 20.h),

                            // Agency label
                            Text(
                              'Agency',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                              ),
                              child: TextField(
                                controller: controller.agencyController,
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter agency name',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // Incident ID label
                            Text(
                              'Incident ID',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                              ),
                              child: TextField(
                                controller: controller.incidentIdController,
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  color: const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter incident ID',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Card 2: Requested Type
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.015),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requested Type',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Checkbox items
                            ...controller.requestedTypes.keys.map((key) {
                              return Obx(() {
                                final isChecked = controller.requestedTypes[key] ?? false;
                                return GestureDetector(
                                  onTap: () => controller.toggleType(key),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1.w,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Custom Checkbox shape matching mockup style
                                        Container(
                                          width: 20.r,
                                          height: 20.r,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: isChecked
                                                  ? const Color(0xFF1550A6)
                                                  : const Color(0xFF94A3B8),
                                              width: 1.5.w,
                                            ),
                                            borderRadius: BorderRadius.circular(4.r),
                                          ),
                                          child: isChecked
                                              ? Icon(
                                                  Icons.check_rounded,
                                                  color: const Color(0xFF1550A6),
                                                  size: 14.sp,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: 16.w),
                                        Text(
                                          key,
                                          style: GoogleFonts.inter(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                            }),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Generate Button
                      CustomButton(
                        text: 'Generate Signed Subpoena',
                        onPressed: () => controller.generateSubpoena(),
                        backgroundColor: const Color(0xFF1550A6),
                        borderRadius: 24,
                      ),
                      SizedBox(height: 24.h),
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
}
