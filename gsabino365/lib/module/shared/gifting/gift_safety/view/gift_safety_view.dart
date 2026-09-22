import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/widgets/custom_button.dart';
import 'package:gsabino365/module/shared/gifting/gift_safety/controller/gift_safety_controller.dart';

class GiftSafetyView extends GetView<GiftSafetyController> {
  const GiftSafetyView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
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

                // Main Title & Subtitle (Centered matching screenshot style)
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        'Gift Safety',
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Generate premium protection codes\nfor your family members.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Selection Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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

                      // Quantity Selector
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
                            width: 100.w,
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
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                color: const Color(0xFF0F172A),
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // Price Calculation Pill
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

                // Purchase Button
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
    );
  }
}
