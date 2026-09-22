import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class CitizenRegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final languagesController = TextEditingController();
  final preferredAttorneyController = TextEditingController();
  final preferredBailBondsmanController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordObscured = true.obs;

  // Dropdown list for Roles
  final rolesList = ['Citizen', 'Resident', 'Non-Resident'];
  final rxSelectedRole = RxnString();

  String? get selectedRole => rxSelectedRole.value;

  void setSelectedRole(String? val) {
    rxSelectedRole.value = val;
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  Future<void> register() async {
    if (formKey.currentState?.validate() ?? false) {
      if (rxSelectedRole.value == null) {
        Helpers.showError('Please select a category role', title: 'Role Required');
        return;
      }

      isLoading.value = true;
      final authService = Get.find<AuthService>();
      final email = emailController.text.trim();

      final payload = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': email,
        'role': 'CITIZEN',
        'subRole': rxSelectedRole.value,
        'password': passwordController.text,
      };

      if (phoneController.text.trim().isNotEmpty) {
        payload['phoneNumber'] = phoneController.text.trim();
      }
      if (languagesController.text.trim().isNotEmpty) {
        payload['languagesSpoken'] = languagesController.text.trim();
      }
      if (preferredAttorneyController.text.trim().isNotEmpty) {
        payload['preferredAttorney'] = preferredAttorneyController.text.trim();
      }
      if (preferredBailBondsmanController.text.trim().isNotEmpty) {
        payload['preferredBailBondsman'] = preferredBailBondsmanController.text.trim();
      }

      try {
        final response = await authService.register(payload);
        isLoading.value = false;

        final statusCode = response.statusCode ?? 0;
        if (statusCode == 200 || statusCode == 201) {
          Helpers.showSuccess(
            'Citizen account created successfully! Please verify OTP.',
            title: 'Account Created',
          );

          Get.toNamed(
            AppRoutes.otpVerification,
            arguments: {
              'flow': 'signup',
              'role': 'CITIZEN',
              'email': email,
            },
          );
        } else {
          final message = response.statusMessage ??
              (response.data is Map ? response.data['message']?.toString() : null) ??
              'Registration failed';
          Helpers.showError(message, title: 'Registration Failed');
        }
      } catch (e) {
        isLoading.value = false;
        Helpers.showError('An error occurred. Please check your network and try again.');
      }
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    languagesController.dispose();
    preferredAttorneyController.dispose();
    preferredBailBondsmanController.dispose();
    super.onClose();
  }
}
