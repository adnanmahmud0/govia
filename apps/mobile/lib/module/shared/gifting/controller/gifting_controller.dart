import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/shared/gifting/models/gift_package_model.dart';
import 'package:gsabino365/module/shared/gifting/models/gift_code_model.dart';
import 'package:gsabino365/module/shared/gifting/services/gifting_api_service.dart';
import 'package:gsabino365/module/shared/subscription/controller/subscription_controller.dart';
import 'package:gsabino365/module/shared/gifting/widgets/redemption_success_dialog.dart';

class GiftingController extends GetxController {
  final GiftingApiService _apiService = GiftingApiService();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _iapSubscription;

  // Active Tab: 0 = "Gift Subscriptions", 1 = "Redeem Code"
  final RxInt selectedTab = 0.obs;

  // Packages State
  final RxList<GiftPackageModel> packages =
      <GiftPackageModel>[...GiftPackageModel.defaultPackages].obs;
  final Rxn<GiftPackageModel> selectedPackage = Rxn<GiftPackageModel>(
    GiftPackageModel.defaultPackages.isNotEmpty
        ? GiftPackageModel.defaultPackages.first
        : null,
  );
  final RxBool isLoadingPackages = false.obs;
  final RxBool isPurchasing = false.obs;

  // My Gifted Codes & Tracking State
  final RxList<GiftCodeModel> myGiftedCodes = <GiftCodeModel>[].obs;
  final RxBool isLoadingMyCodes = false.obs;
  final RxInt totalPurchasedCount = 0.obs;
  final RxInt totalRedeemedCount = 0.obs;
  final RxInt totalAvailableCount = 0.obs;

  // Redemption State
  final TextEditingController codeInputController = TextEditingController();
  final RxBool isValidatingCode = false.obs;
  final RxBool isRedeeming = false.obs;
  final Rxn<GiftCodePreviewModel> verifiedPreview = Rxn<GiftCodePreviewModel>();
  final RxString validationError = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // Check if initial tab was passed in arguments
    if (Get.arguments is Map && Get.arguments['tab'] != null) {
      selectedTab.value = (Get.arguments['tab'] as num).toInt();
    }

    _initializeIapListener();
    fetchPackages();
    fetchMyGiftedCodes();
  }

  @override
  void onClose() {
    _iapSubscription?.cancel();
    codeInputController.dispose();
    super.onClose();
  }

  void switchTab(int index) {
    selectedTab.value = index;
    if (index == 0 && myGiftedCodes.isEmpty) {
      fetchMyGiftedCodes();
    }
  }

  // ==========================================
  // IAP Listener for Consumable Gift Passes
  // ==========================================
  void _initializeIapListener() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _iapSubscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () => _iapSubscription?.cancel(),
      onError: (error) {
        debugPrint('Gifting IAP Error: $error');
      },
    );
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        isPurchasing.value = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          isPurchasing.value = false;
          Helpers.showError(
              purchaseDetails.error?.message ?? 'Purchase was not completed.');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _verifyAndFulfillConsumable(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _verifyAndFulfillConsumable(
      PurchaseDetails purchaseDetails) async {
    try {
      final token = purchaseDetails.verificationData.serverVerificationData;
      final productId = purchaseDetails.productID;
      final provider =
          GetPlatform.isIOS ? 'APPLE_IAP' : 'GOOGLE_PLAY';

      final result = await _apiService.purchaseGiftPackage(
        productId: productId,
        provider: provider,
        purchaseToken: token,
        transactionId: purchaseDetails.purchaseID,
      );

      isPurchasing.value = false;
      await fetchMyGiftedCodes();

      final count = result?['totalCodes'] ?? 1;
      Get.rawSnackbar(
        title: 'Gift Purchase Successful! 🎉',
        message: 'Generated $count gift code${count > 1 ? 's' : ''}. Share them below!',
        backgroundColor: const Color(0xFF1550A6),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      isPurchasing.value = false;
      Helpers.showError('Unable to verify gift purchase: $e');
    }
  }

  // ==========================================
  // Fetch Packages & Purchased Codes
  // ==========================================
  Future<void> fetchPackages() async {
    try {
      isLoadingPackages.value = true;
      final items = await _apiService.fetchGiftPackages();
      if (items.isNotEmpty) {
        packages.assignAll(items);
        if (selectedPackage.value == null ||
            !packages.any((p) => p.productId == selectedPackage.value?.productId)) {
          selectedPackage.value = items.first;
        }
      }
    } catch (_) {
      // Maintain default packages on error
    } finally {
      isLoadingPackages.value = false;
    }
  }

  Future<void> fetchMyGiftedCodes() async {
    try {
      isLoadingMyCodes.value = true;
      final codes = await _apiService.fetchMyPurchasedGifts();
      myGiftedCodes.assignAll(codes);

      totalPurchasedCount.value = codes.length;
      totalRedeemedCount.value = codes.where((c) => c.isRedeemed).length;
      totalAvailableCount.value = codes.where((c) => !c.isRedeemed).length;
    } finally {
      isLoadingMyCodes.value = false;
    }
  }

  void selectPackage(GiftPackageModel pkg) {
    selectedPackage.value = pkg;
  }

  // ==========================================
  // Purchase Gift Package
  // ==========================================
  Future<void> purchaseSelectedPackage() async {
    final pkg = selectedPackage.value;
    if (pkg == null) return;

    try {
      isPurchasing.value = true;

      final isAvailable = await _inAppPurchase.isAvailable();
      if (isAvailable && !GetPlatform.isWeb) {
        final ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails({pkg.productId});

        if (response.productDetails.isNotEmpty) {
          final productDetails = response.productDetails.first;
          final purchaseParam =
              PurchaseParam(productDetails: productDetails);

          // Buy as consumable (allows repeated gifting)
          await _inAppPurchase.buyConsumable(
            purchaseParam: purchaseParam,
            autoConsume: true,
          );
          return;
        }
      }

      // Sandbox / direct checkout fallback for web, simulators, or testing
      final result = await _apiService.purchaseGiftPackage(
        productId: pkg.productId,
        provider: 'MANUAL',
      );

      isPurchasing.value = false;
      await fetchMyGiftedCodes();

      final count = result?['totalCodes'] ?? pkg.unitsCount;
      Get.rawSnackbar(
        title: 'Gift Purchase Successful! 🎉',
        message: 'Successfully generated $count gift code${count > 1 ? 's' : ''} for \$${pkg.price.toStringAsFixed(2)}!',
        backgroundColor: const Color(0xFF1550A6),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      isPurchasing.value = false;
      Helpers.showError('Could not complete purchase: $e');
    }
  }

  // ==========================================
  // Code Copy & Sharing
  // ==========================================
  void copyGiftCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Get.rawSnackbar(
      message: 'Gift Code copied to clipboard: $code',
      backgroundColor: const Color(0xFF1550A6),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void shareGiftCode(GiftCodeModel item) {
    final shareText =
        'Here is your Govia Safety & Protection subscription gift!\n\n'
        '🎁 Gift Code: ${item.code}\n'
        '📋 Plan: ${item.formattedPlanTitle}\n\n'
        'Download the Govia app and enter this code in the Gifting Hub to activate your emergency protection coverage!';

    Clipboard.setData(ClipboardData(text: shareText));
    Get.rawSnackbar(
      title: 'Gift Message Copied!',
      message: 'Ready to share via SMS, WhatsApp, or Email.',
      backgroundColor: const Color(0xFF1550A6),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ==========================================
  // Redemption Actions
  // ==========================================
  void pasteCodeFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      codeInputController.text = data.text!.trim().toUpperCase();
      validationError.value = '';
    }
  }

  Future<void> validateCode() async {
    final code = codeInputController.text.trim();
    if (code.isEmpty) {
      validationError.value = 'Please enter a valid gift code';
      return;
    }

    try {
      isValidatingCode.value = true;
      validationError.value = '';
      verifiedPreview.value = null;

      final preview = await _apiService.validateGiftCode(code);
      verifiedPreview.value = preview;
    } catch (e) {
      validationError.value = e.toString();
      verifiedPreview.value = null;
    } finally {
      isValidatingCode.value = false;
    }
  }

  Future<void> redeemVerifiedCode() async {
    final code = codeInputController.text.trim();
    if (code.isEmpty) return;

    try {
      isRedeeming.value = true;
      final result = await _apiService.redeemGiftCode(code);

      // Refresh app-wide subscription status if SubscriptionController is loaded
      if (Get.isRegistered<SubscriptionController>()) {
        Get.find<SubscriptionController>().fetchSubscriptionStatus();
      }

      final planTitle =
          result['plan'] == 'PREMIUM_YEARLY' ? '1 Year VIP Pass' : '1 Month Safety Pass';
      final giverName = result['giverName'] ?? 'A generous friend';

      // Clear code input and preview
      codeInputController.clear();
      verifiedPreview.value = null;
      validationError.value = '';

      // Trigger Celebration Dialog
      Get.dialog(
        RedemptionSuccessDialog(
          planTitle: planTitle,
          giverName: giverName,
          onClose: () {
            Get.back(); // close dialog
            switchTab(0); // switch back to dashboard
          },
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Helpers.showError(e.toString());
    } finally {
      isRedeeming.value = false;
    }
  }
}
