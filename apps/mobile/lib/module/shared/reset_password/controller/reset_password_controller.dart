import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/shared/reset_password/view/widgets/success_dialog.dart';

class ResetPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;
  final RxBool isLoading = false.obs;

  late final String token;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      token = args['resetToken']?.toString() ?? '';
    } else {
      token = args?.toString() ?? '';
    }
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  Future<void> resetPassword() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final newPass = passwordController.text;
    final confirmPass = confirmPasswordController.text;

    if (newPass != confirmPass) {
      Helpers.showError('Passwords do not match');
      return;
    }

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      final response = await authService.resetPassword(
        resetToken: token,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200 || statusCode == 201) {
        Get.dialog(const SuccessDialog(), barrierDismissible: false);
      } else {
        final message = response.statusMessage ??
            (response.data is Map ? response.data['message']?.toString() : null) ??
            'Failed to reset password.';
        Helpers.showError(message, title: 'Error');
      }
    } catch (e) {
      Helpers.showError('An error occurred while resetting password.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
