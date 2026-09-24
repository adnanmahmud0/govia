import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionPlanItem {
  final String id;
  final String title;
  final double monthlyPrice;
  final double yearlyPrice;
  final String description;
  final List<String> features;
  final List<String> lockedFeatures;
  final String? badge;

  SubscriptionPlanItem({
    required this.id,
    required this.title,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.description,
    required this.features,
    this.lockedFeatures = const [],
    this.badge,
  });
}

class SubscriptionController extends GetxController {
  late final ApiClient _apiClient;

  // Selected Billing Option ('monthly' or 'yearly')
  final RxString selectedBillingCycle = 'yearly'.obs;
  final RxString selectedPlanId = 'premium'.obs;

  // Loading States
  final RxBool isLoading = false.obs;
  final RxBool isPurchasing = false.obs;

  // User Current Subscription & Quota State from Backend
  final RxString currentPlan = 'FREE'.obs;
  final RxBool isPremium = false.obs;
  final RxBool isCitizen = true.obs;
  final RxInt usedMeetings = 0.obs;
  final RxInt limitMeetings = 3.obs;
  final RxInt remainingMeetings = 3.obs;
  final RxBool canViewRecordings = false.obs;
  final RxBool hasDoctorSupport = false.obs;
  final RxBool hasPremiumAI = false.obs;
  final RxString activeExpiryDate = ''.obs;

  // In-App Purchase Stream Subscription
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final InAppPurchase _iap = InAppPurchase.instance;
  final RxBool isStoreAvailable = false.obs;

  // App Store & Play Store Product Identifiers
  static const String monthlyProductId = 'govia_premium_monthly';
  static const String yearlyProductId = 'govia_premium_yearly';
  static const Set<String> _productIds = {
    monthlyProductId,
    yearlyProductId,
  };

  final List<ProductDetails> availableProducts = <ProductDetails>[];

  // Static definition of citizen tiers
  final List<SubscriptionPlanItem> plans = [
    SubscriptionPlanItem(
      id: 'free',
      title: 'Community Free',
      monthlyPrice: 0.0,
      yearlyPrice: 0.0,
      description: 'Standard emergency coverage for community citizens.',
      features: [
        '3 Emergency / Start Govia Calls per Month',
        'GoVia AI Legal Assistant (Community AI Model)',
        'GPS Incident Tracking & Time Logging',
        'Standard Dispatch Routing',
      ],
      lockedFeatures: [
        'No Cloud Recording Playback & Archive',
        'No Doctor or Mental Health Support',
        'No High-Speed GPT-4o / Claude AI Legal Copilot',
        'No Court-Admissible Tamper-Proof Evidence Vault',
      ],
      badge: 'Community',
    ),
    SubscriptionPlanItem(
      id: 'premium',
      title: 'Govia Premium',
      monthlyPrice: 9.99,
      yearlyPrice: 79.99, // $6.67/mo (Save 33%)
      description: 'Comprehensive, unlimited public safety, legal & medical coverage.',
      features: [
        'Unlimited 24/7 Emergency & Govia Consultations',
        'Full Incident Cloud Video Archive & Playback',
        '24/7 Licensed Doctor & Mental Health Support',
        'Confidential Doctor Telehealth & Direct Chat',
        'Advanced High-Speed Legal AI (GPT-4o / Claude)',
        'Priority Dispatch to Preferred Attorneys & Bondsmen',
        'Tamper-Proof Evidence Vault & PDF Legal Export',
      ],
      lockedFeatures: [],
      badge: 'Recommended',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _apiClient = Get.isRegistered<ApiClient>()
        ? Get.find<ApiClient>()
        : Get.put(ApiClient());

    _initInAppPurchases();
    fetchSubscriptionStatus();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Initialize Google Play Billing & Apple StoreKit
  Future<void> _initInAppPurchases() async {
    try {
      final available = await _iap.isAvailable();
      isStoreAvailable.value = available;

      if (available) {
        final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (error) {
            debugPrint('[IAP Stream Error] $error');
          },
        );

        final ProductDetailsResponse response =
            await _iap.queryProductDetails(_productIds);
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('[IAP Warning] Product IDs not found in store: ${response.notFoundIDs}');
        }
        availableProducts.assignAll(response.productDetails);
      }
    } catch (e) {
      debugPrint('[IAP Init Exception] $e');
      isStoreAvailable.value = false;
    }
  }

  /// Handle Google & Apple Purchase Stream Events
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        isPurchasing.value = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          isPurchasing.value = false;
          Helpers.showError(
            purchaseDetails.error?.message ?? 'Payment failed or cancelled',
            title: 'Purchase Error',
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _verifyAndActivateIap(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Send Purchase Token / Receipt to Backend Verifier
  Future<void> _verifyAndActivateIap(PurchaseDetails purchaseDetails) async {
    try {
      isPurchasing.value = true;
      final provider = Platform.isIOS ? 'APPLE_IAP' : 'GOOGLE_PLAY';
      final token = purchaseDetails.verificationData.serverVerificationData;

      final response = await _apiClient.postData('/subscriptions/verify-iap', {
        'provider': provider,
        'productId': purchaseDetails.productID,
        'token': token,
      });

      if (response.statusCode == 200) {
        HapticFeedback.heavyImpact();
        Helpers.showSuccess(
          'Congratulations! Govia Premium is now active on your account.',
          title: 'Premium Activated',
        );
        await fetchSubscriptionStatus();
      } else {
        Helpers.showError('Verification failed. Please contact support.');
      }
    } catch (e) {
      Helpers.showError('Verification error: $e');
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Fetch Real-time Subscription Quota and Features from Backend
  Future<void> fetchSubscriptionStatus() async {
    try {
      isLoading.value = true;
      final response = await _apiClient.getData('/subscriptions/my-status');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is Map<String, dynamic>) {
          currentPlan.value = data['plan']?.toString() ?? 'FREE';
          isPremium.value = data['isPremium'] == true;
          isCitizen.value = data['isCitizen'] != false;

          final usage = data['monthlyUsage'];
          if (usage is Map<String, dynamic>) {
            usedMeetings.value = usage['used'] is num ? (usage['used'] as num).toInt() : 0;
            limitMeetings.value = usage['limit'] is num ? (usage['limit'] as num).toInt() : 3;
            remainingMeetings.value = usage['remaining'] is num
                ? (usage['remaining'] as num).toInt()
                : (isPremium.value ? -1 : 3);
          }

          final features = data['features'];
          if (features is Map<String, dynamic>) {
            canViewRecordings.value = features['canViewRecordings'] == true;
            hasDoctorSupport.value = features['hasDoctorSupport'] == true;
            hasPremiumAI.value = features['hasPremiumAI'] == true;
          }

          if (data['endDate'] != null) {
            activeExpiryDate.value = data['endDate'].toString();
          }
        }
      }
    } catch (_) {
      // Fallback defaults in case of network interruption
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle between Monthly and Yearly Billing
  void toggleBillingCycle(String cycle) {
    selectedBillingCycle.value = cycle;
    HapticFeedback.selectionClick();
  }

  /// Trigger Subscription Purchase
  Future<void> subscribe() async {
    final isYearly = selectedBillingCycle.value == 'yearly';
    final targetProductId = isYearly ? yearlyProductId : monthlyProductId;

    // 1. Attempt Native Google Play / Apple StoreKit Flow if store is live
    if (isStoreAvailable.value && availableProducts.isNotEmpty) {
      try {
        final product = availableProducts.firstWhere(
          (p) => p.id == targetProductId,
          orElse: () => availableProducts.first,
        );

        final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
        isPurchasing.value = true;
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        return;
      } catch (e) {
        debugPrint('[IAP Trigger Exception] $e');
      }
    }

    // 2. Direct Backend Activation Fallback (for sandbox, dev testing, or direct web activation)
    try {
      isPurchasing.value = true;
      final planName = isYearly ? 'PREMIUM_YEARLY' : 'PREMIUM_MONTHLY';

      final response = await _apiClient.postData('/subscriptions/subscribe', {
        'plan': planName,
        'paymentProvider': Platform.isIOS ? 'APPLE_IAP' : 'GOOGLE_PLAY',
      });

      if (response.statusCode == 200) {
        HapticFeedback.heavyImpact();
        Helpers.showSuccess(
          'You are now subscribed to Govia Premium (${isYearly ? 'Yearly' : 'Monthly'})!',
          title: 'Upgrade Successful',
        );
        await fetchSubscriptionStatus();
      } else {
        Helpers.showError('Subscription activation could not be completed.');
      }
    } catch (e) {
      Helpers.showError('Unable to activate subscription: $e');
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Helper to calculate current displayed price
  String getCurrentPriceLabel() {
    if (selectedBillingCycle.value == 'yearly') {
      return '\$79.99 / year';
    }
    return '\$9.99 / month';
  }

  /// Helper for monthly equivalent savings text
  String getSavingsSubtext() {
    if (selectedBillingCycle.value == 'yearly') {
      return 'Just \$6.67/month • Billed annually (Save 33%)';
    }
    return 'Billed monthly • Cancel anytime';
  }
}
