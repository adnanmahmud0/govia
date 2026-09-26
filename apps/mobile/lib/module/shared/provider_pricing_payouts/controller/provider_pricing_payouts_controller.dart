import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/repositories/provider_payment_repository.dart';
import 'package:gsabino365/module/shared/widgets/stripe_webview_modal.dart';

class ProviderPricingPayoutsController extends GetxController {
  late final ProviderPaymentRepository _repo;
  late final AuthService _authService;

  final monthlyFeeController = TextEditingController();
  final serviceFeeController = TextEditingController();
  final shortDescriptionController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isSettingUpPayouts = false.obs;

  // Stripe status
  final RxBool payoutsEnabled = false.obs;
  final RxString stripeAccountId = ''.obs;
  final RxString stripeAccountStatus = 'NOT_CREATED'.obs;

  @override
  void onInit() {
    super.onInit();
    final apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : Get.put(ApiClient());
    _repo = ProviderPaymentRepository(apiClient: apiClient);
    _authService = Get.find<AuthService>();

    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      // 1. Sync from current user
      final user = _authService.currentUser.value;
      if (user != null) {
        if (user.monthlyServiceFee != null && user.monthlyServiceFee! > 0) {
          monthlyFeeController.text = user.monthlyServiceFee!.toStringAsFixed(2);
        }
        if (user.serviceFee != null && user.serviceFee! > 0) {
          serviceFeeController.text = user.serviceFee!.toStringAsFixed(2);
        }
        if (user.shortDescription != null && user.shortDescription!.isNotEmpty) {
          shortDescriptionController.text = user.shortDescription!;
        }
        payoutsEnabled.value = user.payoutsEnabled ?? false;
        stripeAccountId.value = user.stripeAccountId ?? '';
        stripeAccountStatus.value = user.stripeAccountStatus ?? 'NOT_CREATED';
      }

      // 2. Fetch latest pricing & payout status from server
      final pricing = await _repo.getPricingProfile();
      if (pricing != null) {
        if (pricing['monthlyServiceFee'] != null) {
          monthlyFeeController.text =
              (pricing['monthlyServiceFee'] as num).toDouble().toStringAsFixed(2);
        }
        if (pricing['serviceFee'] != null) {
          serviceFeeController.text =
              (pricing['serviceFee'] as num).toDouble().toStringAsFixed(2);
        }
        if (pricing['shortDescription'] != null) {
          shortDescriptionController.text = pricing['shortDescription'].toString();
        }
      }

      final payoutStatus = await _repo.getPayoutStatus();
      if (payoutStatus != null) {
        payoutsEnabled.value = payoutStatus['payoutsEnabled'] == true;
        stripeAccountId.value = payoutStatus['accountId']?.toString() ?? '';
        stripeAccountStatus.value = payoutStatus['status']?.toString() ?? 'NOT_CREATED';
      }
    } catch (e) {
      debugPrint('Error loading provider pricing & payout data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePricingProfile() async {
    final monthlyFee = double.tryParse(monthlyFeeController.text.trim()) ?? 0.0;
    final serviceFee = double.tryParse(serviceFeeController.text.trim()) ?? 0.0;
    final bio = shortDescriptionController.text.trim();

    if (monthlyFee <= 0) {
      Helpers.showError('Please specify a monthly retainer fee greater than \$0.00');
      return;
    }

    if (serviceFee <= 0) {
      Helpers.showError('Please specify a per-encounter service fee greater than \$0.00');
      return;
    }

    if (bio.isEmpty) {
      Helpers.showError('Please write a brief bio or description of your services.');
      return;
    }

    isSaving.value = true;
    try {
      final res = await _repo.updatePricingProfile(
        monthlyServiceFee: monthlyFee,
        serviceFee: serviceFee,
        shortDescription: bio,
      );

      if (res.statusCode == 200) {
        // Refresh local user profile
        await _authService.getProfile();
        Helpers.showSuccess('Service pricing and bio saved successfully!');
      } else {
        Helpers.showError(res.data?['message'] ?? 'Failed to update pricing profile.');
      }
    } catch (e) {
      Helpers.showError('An error occurred while saving: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> setupStripePayouts(BuildContext context) async {
    isSettingUpPayouts.value = true;
    try {
      final result = await _repo.createPayoutAccount();
      if (result != null && result['onboardingUrl'] != null) {
        final onboardingUrl = result['onboardingUrl'].toString();

        if (context.mounted) {
          await StripeWebviewModal.show(
            context: context,
            initialUrl: onboardingUrl,
            title: 'Stripe Express Payout Onboarding',
            onConnectComplete: () async {
              await _refreshPayoutStatus();
              Helpers.showSuccess('Stripe onboarding completed! Updating status...');
            },
          );
        }
      } else {
        Helpers.showError('Failed to generate Stripe onboarding link. Please try again.');
      }
    } catch (e) {
      Helpers.showError('Stripe onboarding error: $e');
    } finally {
      isSettingUpPayouts.value = false;
      await _refreshPayoutStatus();
    }
  }

  Future<void> openStripeDashboard(BuildContext context) async {
    try {
      final url = await _repo.getPayoutDashboardLink();
      if (url != null && url.isNotEmpty) {
        if (context.mounted) {
          await StripeWebviewModal.show(
            context: context,
            initialUrl: url,
            title: 'Stripe Express Dashboard',
          );
        }
      } else {
        Helpers.showError('Could not load Stripe dashboard link. Please verify payout setup.');
      }
    } catch (e) {
      Helpers.showError('Dashboard error: $e');
    }
  }

  Future<void> _refreshPayoutStatus() async {
    try {
      final payoutStatus = await _repo.getPayoutStatus();
      if (payoutStatus != null) {
        payoutsEnabled.value = payoutStatus['payoutsEnabled'] == true;
        stripeAccountId.value = payoutStatus['accountId']?.toString() ?? '';
        stripeAccountStatus.value = payoutStatus['status']?.toString() ?? 'NOT_CREATED';
      }
      await _authService.getProfile();
    } catch (_) {}
  }

  @override
  void onClose() {
    monthlyFeeController.dispose();
    serviceFeeController.dispose();
    shortDescriptionController.dispose();
    super.onClose();
  }
}
