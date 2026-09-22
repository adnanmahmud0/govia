import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttorneySubpoenaRequestController extends GetxController {
  late TextEditingController agencyController;
  late TextEditingController incidentIdController;

  final RxString selectedCourt = 'Central District Superior Court'.obs;
  final List<String> courts = [
    'Central District Superior Court',
    'Northern District Court',
    'Southern Municipal Court',
    'State Supreme Court',
  ];

  final RxMap<String, bool> requestedTypes = {
    'Bodycam Footage': false,
    'Dashcam Footage': false,
    'Radio Logs': false,
    'Cameras & Audio': false,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    agencyController = TextEditingController(text: 'Metropolitan Police Department');
    incidentIdController = TextEditingController(text: '2024-CR-5501');
  }

  void toggleType(String key) {
    requestedTypes[key] = !(requestedTypes[key] ?? false);
  }

  void generateSubpoena() {
    final agency = agencyController.text.trim();
    final incidentId = incidentIdController.text.trim();

    if (agency.isEmpty) {
      Get.snackbar(
        'Required Field',
        'Please enter the agency name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    if (incidentId.isEmpty) {
      Get.snackbar(
        'Required Field',
        'Please enter the incident ID.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    final selectedItems = requestedTypes.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedItems.isEmpty) {
      Get.snackbar(
        'Selection Required',
        'Please select at least one requested evidence type.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    Get.back(); // Return to profile or previous screen
    Get.snackbar(
      'Subpoena Generated',
      'Digitally signed subpoena request submitted successfully to $agency for Incident $incidentId!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    agencyController.dispose();
    incidentIdController.dispose();
    super.onClose();
  }
}
