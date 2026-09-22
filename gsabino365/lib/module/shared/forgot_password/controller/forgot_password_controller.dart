import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final RxBool isLoading = false.obs;

  // Selected role (backend requires email + role for forget password)
  final RxString selectedRole = 'CITIZEN'.obs;

  final List<String> availableRoles = const [
    'CITIZEN',
    'ATTORNEY',
    'POLICE',
    'MENTAL_HEALTH_PROFESSIONAL',
    'BAIL_BONDSMAN',
  ];

  final Map<String, String> roleLabels = const {
    'CITIZEN': 'Citizen',
    'ATTORNEY': 'Attorney',
    'POLICE': 'Police Officer',
    'MENTAL_HEALTH_PROFESSIONAL': 'Mental Health Professional',
    'BAIL_BONDSMAN': 'Bail Bondsman',
  };

  void setSelectedRole(String? role) {
    if (role != null && role.isNotEmpty) {
      selectedRole.value = role;
    }
  }

  Future<void> sendOtpCode() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    final role = selectedRole.value;

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      final response = await authService.forgotPassword(
        email: email,
        role: role,
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200 || statusCode == 201) {
        Helpers.showSuccess(
          'OTP code sent to your email successfully.',
          title: 'Code Sent',
        );

        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {
            'email': email,
            'role': role,
            'flow': 'forgot_password',
          },
        );
      } else {
        final message = response.statusMessage ??
            (response.data is Map ? response.data['message']?.toString() : null) ??
            'Failed to send OTP code.';
        Helpers.showError(message, title: 'Error');
      }
    } catch (e) {
      Helpers.showError('An error occurred. Please check your connection and try again.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
