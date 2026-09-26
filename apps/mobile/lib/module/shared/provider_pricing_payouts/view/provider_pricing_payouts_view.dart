import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/module/shared/provider_pricing_payouts/controller/provider_pricing_payouts_controller.dart';

class ProviderPricingPayoutsView extends GetView<ProviderPricingPayoutsController> {
  const ProviderPricingPayoutsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Blue Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1550A6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 16.w,
                right: 24.w,
                top: MediaQuery.of(context).padding.top + 12.h,
                bottom: 24.h,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Pricing & Payouts',
                          style: GoogleFonts.outfit(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Rates, bio description & Stripe Express',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1550A6)),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stripe Payout Account Card
                      _buildStripePayoutSection(context),

                      SizedBox(height: 20.h),

                      // Service Pricing Card
                      _buildPricingConfigSection(),

                      SizedBox(height: 24.h),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1550A6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.savePricingProfile(),
                          child: controller.isSaving.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save Pricing & Bio',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Commission policy banner
                      Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'GoVia retains a 10% platform commission on retained monthly subscriptions and emergency encounters. 90% is deposited directly into your bank via Stripe Express.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  color: const Color(0xFF475569),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStripePayoutSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: controller.payoutsEnabled.value
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFED7AA),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: controller.payoutsEnabled.value
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFF97316).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: controller.payoutsEnabled.value
                      ? const Color(0xFF059669)
                      : const Color(0xFFEA580C),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stripe Payout System',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      controller.payoutsEnabled.value
                          ? 'Payouts Active • Automatic Transfers'
                          : 'Action Required • Connect Bank',
                      style: GoogleFonts.inter(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: controller.payoutsEnabled.value
                            ? const Color(0xFF059669)
                            : const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: controller.payoutsEnabled.value
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  controller.payoutsEnabled.value ? 'CONNECTED' : 'INACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: controller.payoutsEnabled.value
                        ? const Color(0xFF059669)
                        : const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          Text(
            controller.payoutsEnabled.value
                ? 'Your Stripe Express account is fully set up. When citizens activate your retainer or complete emergency consultations, your earnings are automatically deposited to your bank.'
                : 'Connect your bank account via Stripe Express. Once verified, you will appear in the public marketplace for citizens to retain your services.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),

          SizedBox(height: 14.h),

          if (!controller.payoutsEnabled.value)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF635BFF), // Stripe brand purple
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onPressed: controller.isSettingUpPayouts.value
                    ? null
                    : () => controller.setupStripePayouts(context),
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Set Up Stripe Express Payouts',
                  style: GoogleFonts.inter(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF635BFF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 14.w),
              ),
              onPressed: () => controller.openStripeDashboard(context),
              icon: const Icon(Icons.dashboard_rounded, color: Color(0xFF635BFF), size: 16),
              label: Text(
                'Open Stripe Express Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF635BFF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingConfigSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Rates & Presentation',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Citizens will see these prices and your bio when selecting you in the marketplace.',
            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
          ),

          SizedBox(height: 18.h),

          // Monthly Retainer Fee Field
          Text(
            'Monthly Retainer Service Fee (\$ / month)',
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller.monthlyFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              hintText: '99.00',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Paid upfront by citizens to retain you as their Preferred Provider for 30 days.',
            style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
          ),

          SizedBox(height: 18.h),

          // Per-Encounter Fee Field
          Text(
            'Per-Encounter Service Fee (\$ / emergency consultation)',
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller.serviceFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              hintText: '150.00',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Automatically transferred directly to your Stripe account when an emergency encounter meeting ends.',
            style: GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFF94A3B8)),
          ),

          SizedBox(height: 18.h),

          // Bio / Short Description Field
          Text(
            'Short Bio / Service Description',
            style: GoogleFonts.inter(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller.shortDescriptionController,
            maxLines: 3,
            maxLength: 240,
            decoration: InputDecoration(
              hintText: 'e.g. Dedicated legal advocate with 10+ years specializing in roadside encounters, civil rights defense, and immediate emergency representation.',
              hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
              ),
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
        ],
      ),
    );
  }
}
