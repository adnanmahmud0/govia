import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/shared/gifting/models/gift_code_model.dart';

class GiftCodeCard extends StatelessWidget {
  final GiftCodeModel codeItem;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const GiftCodeCard({
    super.key,
    required this.codeItem,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isRedeemed = codeItem.isRedeemed;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isRedeemed
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF1550A6).withValues(alpha: 0.3),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Plan & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      codeItem.plan.contains('YEARLY')
                          ? Icons.verified_rounded
                          : Icons.shield_rounded,
                      color: const Color(0xFF1550A6),
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        codeItem.formattedPlanTitle,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Status Pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isRedeemed
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isRedeemed
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF6EE7B7),
                    width: 0.8.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        color: isRedeemed
                            ? const Color(0xFF64748B)
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      isRedeemed ? 'REDEEMED' : 'AVAILABLE',
                      style: GoogleFonts.inter(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isRedeemed
                            ? const Color(0xFF64748B)
                            : const Color(0xFF065F46),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Code Display Box
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    codeItem.code,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isRedeemed
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF1E293B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // Copy Action
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      color: const Color(0xFF1550A6),
                      size: 15.sp,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // Share Action
                GestureDetector(
                  onTap: onShare,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Icon(
                      Icons.share_rounded,
                      color: const Color(0xFF1550A6),
                      size: 15.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // If REDEEMED: Show who redeemed it!
          if (isRedeemed) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8.w),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: const Color(0xFF2563EB),
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF1E3A8A),
                            ),
                            children: [
                              const TextSpan(text: 'Used by: '),
                              TextSpan(
                                text: codeItem.redeemedByName ?? 'Recipient',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              if (codeItem.redeemedByEmail != null &&
                                  codeItem.redeemedByEmail!.isNotEmpty)
                                TextSpan(
                                  text: ' (${codeItem.redeemedByEmail})',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (codeItem.formattedRedeemedDate.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              'Redeemed on ${codeItem.formattedRedeemedDate}',
                              style: GoogleFonts.inter(
                                fontSize: 10.5.sp,
                                color: const Color(0xFF60A5FA),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
