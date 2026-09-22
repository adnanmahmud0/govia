import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/shared/gifting/organization_details/controller/organization_details_controller.dart';

class OrganizationDetailsView extends GetView<OrganizationDetailsController> {
  const OrganizationDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Light App Bar (Back button only)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
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
                      ],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Main Title & Subtitle
                  Text(
                    'Organization Details',
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Identify the entity for the bulk license agreement.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Card 1: Org details
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORGANIZATION TYPE',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                            letterSpacing: 0.5,
                          ),
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
                              value: controller.selectedOrgType.value,
                              items: controller.orgTypes
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type,
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
                                  controller.selectedOrgType.value = val;
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

                        Text(
                          'INSTITUTION NAME',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                            letterSpacing: 0.5,
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
                            controller: controller.nameController,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. Highlight Legal Partners',
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

                  // Card 2: Quantity Selector
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'NUMBER OF CODES',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1550A6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Quantity selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => controller.decrement(),
                              child: Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: const Color(0xFF0F172A),
                                  size: 20.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 32.w),
                            SizedBox(
                              width: 120.w,
                              child: TextField(
                                controller: controller.codeCountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 30.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => controller.updateCodeCount(val),
                              ),
                            ),
                            SizedBox(width: 32.w),
                            GestureDetector(
                              onTap: () => controller.increment(),
                              child: Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1550A6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24.h),

                        // Price pill
                        Obx(() => Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: const Color(0xFF64748B),
                            ),
                            children: [
                              TextSpan(
                                text: '\$${controller.codePrice.value.toStringAsFixed(2)} × ${controller.codeCount.value} = ',
                              ),
                              TextSpan(
                                text: '\$${controller.totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1550A6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Purchase button
                CustomButton(
                  text: 'Purchase and Generate',
                  onPressed: () => controller.purchaseAndGenerate(),
                  backgroundColor: const Color(0xFF1550A6),
                  borderRadius: 24,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
