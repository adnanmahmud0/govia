import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/auth_service.dart';

class ChangePasswordController extends GetxController {
  late TextEditingController oldPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final RxBool showOldPassword = false.obs;
  final RxBool showNewPassword = false.obs;
  final RxBool showConfirmPassword = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    oldPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  void toggleOldPassword() => showOldPassword.toggle();
  void toggleNewPassword() => showNewPassword.toggle();
  void toggleConfirmPassword() => showConfirmPassword.toggle();

  Future<void> updatePassword() async {
    final oldPass = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      Get.snackbar(
        'Error',
        'All password fields are required.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    if (newPass.length < 6) {
      Get.snackbar(
        'Error',
        'New password must be at least 6 characters.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar(
        'Error',
        'Passwords do not match.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      final response = await authService.changePassword(
        currentPassword: oldPass,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(); // Return to settings screen
        Get.snackbar(
          'Success',
          'Password updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1550A6),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      } else {
        final msg = response.data is Map
            ? response.data['message']?.toString()
            : null;
        Get.snackbar(
          'Error',
          msg ?? 'Failed to update password. Please check your current password.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update password: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
