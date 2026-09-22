import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/doctore/dispatch/controller/doctor_dispatch_controller.dart';

class DoctorDispatchView extends GetView<DoctorDispatchController> {
  const DoctorDispatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Column(
            children: [
              // Custom light App Bar
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
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.w,
                          ),
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
                          'Dispatch Resources',
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

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PRIORITY RESOURCES Title
                      Text(
                        'PRIORITY RESOURCES',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Card 1: EMT
                      _buildPriorityCard(
                        id: 'EMT',
                        icon: Icons.local_hospital_outlined,
                        title: 'Request EMT',
                        subtitle: 'Immediate Life Support Dispatch',
                      ),
                      SizedBox(height: 12.h),

                      // Card 2: Crisis
                      _buildPriorityCard(
                        id: 'Crisis',
                        icon: Icons.psychology_outlined,
                        title: 'Request Mobile Crisis Team',
                        subtitle: 'Mental Health Co-Response',
                      ),
                      SizedBox(height: 12.h),

                      // Card 3: Community
                      _buildPriorityCard(
                        id: 'Community',
                        icon: Icons.people_outline_rounded,
                        title: 'Request Community Resources',
                        subtitle: 'Social Services & Support',
                      ),

                      SizedBox(height: 24.h),

                      // Incident Details Block
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x02000000),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incident Details',
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Location field
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Incident Location',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      controller.incidentLocation,
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle,
                                    color: const Color(0xFF1550A6),
                                    size: 18.sp,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // Severity level selector
                            Text(
                              'Severity Level',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Row(
                                children: controller.severities
                                    .map(
                                      (sev) => Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              controller.selectSeverity(sev),
                                          child: Obx(() {
                                            final isSel =
                                                controller
                                                    .selectedSeverity
                                                    .value ==
                                                sev;
                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 10.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSel
                                                    ? Colors.white
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                boxShadow: isSel
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0x0C000000,
                                                          ),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                sev,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  fontWeight: isSel
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isSel
                                                      ? const Color(0xFF1550A6)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            SizedBox(height: 20.h),

                            // Notes for responders
                            Text(
                              'Notes for Responders',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: TextField(
                                controller: controller.notesController,
                                maxLines: 4,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: const Color(0xFF1E293B),
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Specify safety concerns, patient history, or specific unit requirements...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Submit button
                      CustomButton(
                        text: 'Submit Dispatch Request',
                        onPressed: () => controller.submitDispatch(),
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

  Widget _buildPriorityCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    Color cardBg;
    Color textColor;
    Color subColor;
    Color iconBoxBg;
    Color iconColor;
    Color borderColor;

    if (id == 'EMT') {
      cardBg = const Color(0xFF1550A6);
      textColor = Colors.white;
      subColor = Colors.white.withValues(alpha: 0.75);
      iconBoxBg = Colors.white.withValues(alpha: 0.15);
      iconColor = Colors.white;
      borderColor = Colors.transparent;
    } else if (id == 'Crisis') {
      cardBg = const Color(0xFF032B69);
      textColor = Colors.white;
      subColor = Colors.white.withValues(alpha: 0.7);
      iconBoxBg = Colors.white.withValues(alpha: 0.15);
      iconColor = Colors.white;
      borderColor = Colors.transparent;
    } else {
      // Community
      cardBg = Colors.white;
      textColor = const Color(0xFF0F3A79);
      subColor = const Color(0xFF64748B);
      iconBoxBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF1550A6);
      borderColor = const Color(0xFFE2E8F0);
    }

    return GestureDetector(
      onTap: () => controller.selectResource(id),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 1.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0x05000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: iconBoxBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: subColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
