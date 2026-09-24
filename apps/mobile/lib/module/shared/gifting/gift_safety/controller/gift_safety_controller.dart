import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GiftSafetyController extends GetxController {
  late TextEditingController codeCountController;
  final RxInt codeCount = 4.obs;
  final RxDouble codePrice = 9.00.obs;

  double get totalPrice => codeCount.value * codePrice.value;

  @override
  void onInit() {
    super.onInit();
    codeCountController = TextEditingController(text: codeCount.value.toString());
    
    // Sync reactive variable to controller text
    ever(codeCount, (val) {
      if (codeCountController.text != val.toString()) {
        codeCountController.text = val.toString();
      }
    });
  }

  void updateCodeCount(String val) {
    final parsed = int.tryParse(val) ?? 0;
    if (parsed > 0) {
      codeCount.value = parsed;
    } else {
      // Don't force reset to 1 immediately while typing, but keep it >= 0 internally
      codeCount.value = parsed >= 0 ? parsed : 1;
    }
  }

  void increment() {
    if (codeCount.value < 100000) {
      codeCount.value++;
    }
  }

  void decrement() {
    if (codeCount.value > 1) {
      codeCount.value--;
    }
  }

  void purchaseAndGenerate() {
    Get.back(); // Go back to gifting hub
    Get.snackbar(
      'Purchase Successful',
      'Successfully purchased ${codeCount.value} safety codes for \$${totalPrice.toStringAsFixed(2)}!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    codeCountController.dispose();
    super.onClose();
  }
}
