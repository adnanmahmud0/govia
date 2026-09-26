import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/shared/gifting/controller/gifting_controller.dart';
import 'package:gsabino365/module/shared/gifting/widgets/gift_code_card.dart';

class MyGiftedCodesList extends GetView<GiftingController> {
  const MyGiftedCodesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Refresh
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Gifted Codes & Tracking',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Track unclaimed codes and who redeemed each pass.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1550A6)),
              tooltip: 'Refresh codes',
              onPressed: controller.fetchMyGiftedCodes,
            ),
          ],
        ),

        SizedBox(height: 14.h),

        // Summary Counters Row
        Obx(() {
          return Row(
            children: [
              _buildStatChip(
                label: 'Total Gifted',
                value: '${controller.totalPurchasedCount.value}',
                bgColor: const Color(0xFFF1F5F9),
                textColor: const Color(0xFF1E293B),
              ),
              SizedBox(width: 8.w),
              _buildStatChip(
                label: 'Available',
                value: '${controller.totalAvailableCount.value}',
                bgColor: const Color(0xFFECFDF5),
                textColor: const Color(0xFF065F46),
              ),
              SizedBox(width: 8.w),
              _buildStatChip(
                label: 'Redeemed',
                value: '${controller.totalRedeemedCount.value}',
                bgColor: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1E3A8A),
              ),
            ],
          );
        }),

        SizedBox(height: 16.h),

        // Codes List
        Obx(() {
          if (controller.isLoadingMyCodes.value &&
              controller.myGiftedCodes.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: const CircularProgressIndicator(color: Color(0xFF1550A6)),
              ),
            );
          }

          if (controller.myGiftedCodes.isEmpty) {
            return Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 40.sp,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'No gifted codes yet',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Select a package above to purchase and generate gift codes.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: controller.myGiftedCodes.map((codeItem) {
              return GiftCodeCard(
                codeItem: codeItem,
                onCopy: () => controller.copyGiftCode(codeItem.code),
                onShare: () => controller.shareGiftCode(codeItem),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
