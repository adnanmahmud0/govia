import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class DoctorDispatchController extends GetxController {
  // Priority Resources state
  final RxString selectedResource = 'EMT'.obs; // 'EMT', 'Crisis', 'Community'

  // Severity Level state
  final RxString selectedSeverity = 'High'.obs; // 'Low', 'Medium', 'High', 'Critical'
  final List<String> severities = ['Low', 'Medium', 'High', 'Critical'];

  // Text inputs
  final String incidentLocation = '421 Oakhaven Dr, Unit 4B';
  late TextEditingController notesController;

  @override
  void onInit() {
    super.onInit();
    notesController = TextEditingController();
  }

  void selectResource(String resource) {
    selectedResource.value = resource;
    if (resource == 'EMT') {
      Get.toNamed(AppRoutes.doctorRequestEmt);
    } else if (resource == 'Crisis') {
      Get.toNamed(AppRoutes.doctorRequestCrisis);
    } else if (resource == 'Community') {
      Get.toNamed(AppRoutes.doctorRequestCommunity);
    }
  }

  void selectSeverity(String severity) {
    selectedSeverity.value = severity;
  }

  void submitDispatch() {
    Get.back();
    Get.snackbar(
      'Request Submitted',
      'Dispatch request for $selectedResource (${selectedSeverity.value} Severity) has been sent successfully.',
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
    notesController.dispose();
    super.onClose();
  }
}
