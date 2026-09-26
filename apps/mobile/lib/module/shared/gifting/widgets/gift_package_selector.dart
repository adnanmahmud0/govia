import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/shared/gifting/controller/gifting_controller.dart';
import 'package:gsabino365/module/shared/gifting/models/gift_package_model.dart';

class GiftPackageSelector extends GetView<GiftingController> {
  const GiftPackageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description
        Text(
          'Choose a Gift Package',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Select an individual gift pass or a multi-pack for family, clients, or team members.',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),

        SizedBox(height: 16.h),

        // Packages List
        Obx(() {
          if (controller.isLoadingPackages.value &&
              controller.packages.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: const CircularProgressIndicator(color: Color(0xFF1550A6)),
              ),
            );
          }

          if (controller.packages.isEmpty) {
            return Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'No gift packages currently available.',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: controller.packages.map((pkg) {
              return _buildPackageItem(pkg);
            }).toList(),
          );
        }),

        SizedBox(height: 20.h),

        // Purchase Button
        Obx(() {
          final selected = controller.selectedPackage.value;
          final isPurchasing = controller.isPurchasing.value;

          return SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: isPurchasing || selected == null
                  ? null
                  : controller.purchaseSelectedPackage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: isPurchasing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.r,
                          height: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Processing Purchase...',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      selected != null
                          ? 'Purchase & Generate ${selected.unitsCount} Code${selected.unitsCount > 1 ? 's' : ''} • \$${selected.price.toStringAsFixed(2)}'
                          : 'Select a Package to Continue',
                      style: GoogleFonts.inter(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPackageItem(GiftPackageModel pkg) {
    return Obx(() {
      final isSelected = controller.selectedPackage.value?.productId == pkg.productId;

      return GestureDetector(
        onTap: () => controller.selectPackage(pkg),
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? const Color(0xFF1550A6) : const Color(0xFFE2E8F0),
              width: isSelected ? 2.w : 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF1550A6).withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Radio Indicator
                  Container(
                    width: 20.r,
                    height: 20.r,
                    margin: EdgeInsets.only(top: 2.h),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1550A6)
                            : const Color(0xFFCBD5E1),
                        width: 2.w,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10.r,
                              height: 10.r,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF1550A6),
                              ),
                            ),
                          )
                        : null,
                  ),

                  SizedBox(width: 12.w),

                  // Title & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: [
                            Text(
                              pkg.title,
                              style: GoogleFonts.inter(
                                fontSize: 14.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (pkg.badge != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: pkg.badge!.contains('Value')
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  pkg.badge!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: pkg.badge!.contains('Value')
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF1550A6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          pkg.description,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${pkg.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (pkg.discountText != null)
                        Text(
                          pkg.discountText!,
                          style: GoogleFonts.inter(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
