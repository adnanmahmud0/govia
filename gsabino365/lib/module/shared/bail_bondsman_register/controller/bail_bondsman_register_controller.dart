import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class BailBondsmanRegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final languagesController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final companyNameController = TextEditingController();
  final addressController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordObscured = true.obs;

  // Dropdown list for Roles
  final rolesList = ['Bail Agent', 'Agency Owner', 'Agency Manager', 'Other'];
  final rxSelectedRole = RxnString();

  String? get selectedRole => rxSelectedRole.value;

  void setSelectedRole(String? val) {
    rxSelectedRole.value = val;
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  Future<void> register() async {
    final email = emailController.text.trim();
    if (email.isEmpty || passwordController.text.isEmpty) {
      Helpers.showError('Email and password are required.');
      return;
    }

    isLoading.value = true;
    final authService = Get.find<AuthService>();

    final payload = <String, dynamic>{
      'name': nameController.text.trim().isNotEmpty
          ? nameController.text.trim()
          : 'Bail Bondsman',
      'email': email,
      'role': 'BAIL_BONDSMAN',
      'subRole': rxSelectedRole.value ?? 'Bail Agent',
      'password': passwordController.text,
    };

    if (languagesController.text.trim().isNotEmpty) {
      payload['languagesSpoken'] = languagesController.text.trim();
    }
    if (licenseNumberController.text.trim().isNotEmpty) {
      payload['licenseNumber'] = licenseNumberController.text.trim();
    }
    if (companyNameController.text.trim().isNotEmpty) {
      payload['companyName'] = companyNameController.text.trim();
    }
    if (addressController.text.trim().isNotEmpty) {
      payload['businessAddress'] = addressController.text.trim();
    }

    try {
      final response = await authService.register(payload);
      isLoading.value = false;

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200 || statusCode == 201) {
        Helpers.showSuccess(
          'Bail Bondsman account created! Please verify OTP.',
          title: 'Account Created',
        );

        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {
            'flow': 'signup',
            'role': 'BAIL_BONDSMAN',
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

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    languagesController.dispose();
    licenseNumberController.dispose();
    companyNameController.dispose();
    addressController.dispose();
    super.onClose();
  }
}
