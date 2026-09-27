import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/repositories/referral_repository.dart';

class ReferralController extends GetxController {
  late final ReferralRepository _repo;

  ReferralController({ReferralRepository? referralRepository}) {
    if (referralRepository != null) {
      _repo = referralRepository;
    } else {
      final apiClient = Get.isRegistered<ApiClient>()
          ? Get.find<ApiClient>()
          : Get.put(ApiClient());
      _repo = Get.isRegistered<ReferralRepository>()
          ? Get.find<ReferralRepository>()
          : Get.put(ReferralRepository(apiClient: apiClient));
    }
  }

  // Reactive state
  final RxBool isLoading = true.obs;
  final RxBool isRedeeming = false.obs;
  final RxInt pointsBalance = 0.obs;
  final RxInt lifetimePoints = 0.obs;
  final RxInt referralCount = 0.obs;
  final RxString referralCode = ''.obs;
  final RxString referralLink = ''.obs;
  final RxString tier = 'BRONZE'.obs;
  final RxInt tierNextTarget = 500.obs;

  final RxList<Map<String, dynamic>> recentReferrals =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rewardsCatalog =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadReferralData();
  }

  Future<void> loadReferralData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _repo.getReferralSummary(),
        _repo.getReferralHistory(),
        _repo.getRewardsCatalog(),
      ]);

      final summary = results[0] as Map<String, dynamic>?;
      if (summary != null) {
        referralCode.value = (summary['referralCode'] ?? '').toString();
        referralLink.value = (summary['referralLink'] ?? '').toString();
        pointsBalance.value =
            int.tryParse(summary['pointsBalance']?.toString() ?? '0') ?? 0;
        lifetimePoints.value =
            int.tryParse(summary['lifetimePoints']?.toString() ?? '0') ?? 0;
        referralCount.value =
            int.tryParse(summary['referralCount']?.toString() ?? '0') ?? 0;
        tier.value = (summary['tier'] ?? 'BRONZE').toString();
        tierNextTarget.value =
            int.tryParse(summary['tierNextTarget']?.toString() ?? '500') ?? 500;
      }

      final history = results[1] as List<Map<String, dynamic>>?;
      if (history != null) {
        recentReferrals.assignAll(history);
      }

      final catalog = results[2] as List<Map<String, dynamic>>?;
      if (catalog != null && catalog.isNotEmpty) {
        rewardsCatalog.assignAll(catalog);
      } else {
        // Fallback default catalog if server catalog is initializing
        rewardsCatalog.assignAll([
          {
            'id': 'reward_plus_month',
            'title': '1-Month GoVia Plus Extension',
            'description':
                'Instantly add 30 days of GoVia Plus roadside incident and safety coverage to your citizen account.',
            'pointsCost': 1000,
            'category': 'SUBSCRIPTION',
            'badge': 'Most Popular',
            'isPopular': true,
          },
          {
            'id': 'reward_gift_pass',
            'title': '30-Day Family Safety Gift Pass',
            'description':
                'Generate an exclusive GOVIA-GIFT code to share 1 full month of GoVia safety protection with a loved one.',
            'pointsCost': 1000,
            'category': 'GIFT',
            'badge': 'Shareable Gift',
            'isPopular': false,
          },
          {
            'id': 'reward_provider_credit',
            'title': '\$10 Preferred Provider Retainer Credit',
            'description':
                'Redeem an instant \$10 discount voucher towards your next retainer payment to a preferred attorney or bail bondsman.',
            'pointsCost': 500,
            'category': 'CREDIT',
            'badge': 'Instant Savings',
            'isPopular': false,
          },
        ]);
      }
    } catch (e) {
      // In case of network glitch or initial load, fallback gracefully
    } finally {
      isLoading.value = false;
    }
  }

  void copyReferralLink() {
    final link = referralLink.value.isNotEmpty
        ? referralLink.value
        : 'https://govia.org/join?ref=${referralCode.value}';
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'Copied',
      'Referral link copied to clipboard!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  void copyReferralCode() {
    Clipboard.setData(ClipboardData(text: referralCode.value));
    Get.snackbar(
      'Code Copied',
      'Referral code ${referralCode.value} copied to clipboard!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F9D58),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  void shareReferral() {
    final code = referralCode.value;
    final link = referralLink.value.isNotEmpty
        ? referralLink.value
        : 'https://govia.org/join?ref=$code';

    final shareMessage =
        'Join me on GoVia for 24/7 roadside emergency and safety protection! Use my referral code "$code" or tap the link to get 100 welcome bonus points: $link';

    Clipboard.setData(ClipboardData(text: shareMessage));
    Get.snackbar(
      'Invitation Ready to Share',
      'Invitation message & link copied to clipboard! Paste it into SMS, WhatsApp, or email.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> redeemReward(Map<String, dynamic> reward) async {
    final rewardId = reward['id']?.toString() ?? '';
    final title = reward['title']?.toString() ?? 'Reward';
    final pointsCost =
        int.tryParse(reward['pointsCost']?.toString() ?? '0') ?? 0;

    if (pointsBalance.value < pointsCost) {
      Get.snackbar(
        'Insufficient Points',
        'You need $pointsCost points to redeem $title. You currently have ${pointsBalance.value} points.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD93025),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    isRedeeming.value = true;
    try {
      final res = await _repo.redeemReward(rewardId);
      if (res != null && res['success'] == true) {
        final details = res['data'] as Map<String, dynamic>? ?? {};

        // Update balance
        pointsBalance.value =
            int.tryParse(details['newBalance']?.toString() ?? '') ??
                (pointsBalance.value - pointsCost);

        // Close bottom sheet if open
        if (Get.isBottomSheetOpen == true) {
          Get.back();
        }

        // Show Success Celebration Dialog
        _showRedemptionSuccessDialog(title, details);
      } else {
        Get.snackbar(
          'Redemption Failed',
          res?['message']?.toString() ?? 'Unable to process reward redemption.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD93025),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Network error during redemption. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD93025),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isRedeeming.value = false;
    }
  }

  void _showRedemptionSuccessDialog(
      String title, Map<String, dynamic> details) {
    final giftCode = details['giftCode']?.toString();
    final creditCode = details['creditCode']?.toString();
    final actionText = details['action']?.toString() ??
        'Your reward has been successfully activated!';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.h,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 34.sp,
                    color: const Color(0xFF1550A6),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Reward Redeemed!',
                style: GoogleFonts.outfit(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1550A6),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                actionText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  color: const Color(0xFF555555),
                ),
              ),
              if (giftCode != null || creditCode != null) ...[
                SizedBox(height: 16.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFDADCE0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        giftCode ?? creditCode!,
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: const Color(0xFF202124),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: (giftCode ?? creditCode)!));
                          Get.snackbar(
                            'Copied',
                            'Reward code copied to clipboard!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF1550A6),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        child: Icon(
                          Icons.copy_rounded,
                          size: 20.sp,
                          color: const Color(0xFF1550A6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1550A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
