import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OrganizationDetailsController extends GetxController {
  late TextEditingController nameController;
  late TextEditingController codeCountController;

  final RxInt codeCount = 50.obs;
  final RxDouble codePrice = 9.00.obs;

  final RxString selectedOrgType = 'Law Firm'.obs;
  final List<String> orgTypes = [
    'Law Firm',
    'Corporation',
    'School',
    'Non-Profit',
    'Government Agency'
  ];

  double get totalPrice => codeCount.value * codePrice.value;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
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
      codeCount.value = parsed >= 0 ? parsed : 1;
    }
  }

  void increment() {
    if (codeCount.value < 1000000) {
      codeCount.value += 10;
    }
  }

  void decrement() {
    if (codeCount.value > 10) {
      codeCount.value -= 10;
    } else if (codeCount.value > 1) {
      codeCount.value--;
    }
  }

  void purchaseAndGenerate() {
    final instName = nameController.text.trim();
    if (instName.isEmpty) {
      Get.snackbar(
        'Required Field',
        'Please enter the institution name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    Get.back(); // Go back to gifting hub
    Get.snackbar(
      'Bulk Purchase Successful',
      'Successfully purchased ${codeCount.value} bulk codes for $instName (\$${totalPrice.toStringAsFixed(2)})!',
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
    nameController.dispose();
    codeCountController.dispose();
    super.onClose();
  }
}
