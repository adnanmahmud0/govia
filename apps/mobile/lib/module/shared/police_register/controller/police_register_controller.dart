import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class PoliceRegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final languagesController = TextEditingController();
  final badgeNumberController = TextEditingController();
  final assignedNumberController = TextEditingController();
  final departmentController = TextEditingController();
  final carChangeController = TextEditingController();
  final newCarNumberController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordObscured = true.obs;

  // Dropdown list for Roles
  final rolesList = ['Officer', 'Sergeant', 'Lieutenant', 'Detective'];
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
          : 'Officer',
      'email': email,
      'role': 'POLICE',
      'subRole': rxSelectedRole.value ?? 'Officer',
      'password': passwordController.text,
    };

    if (languagesController.text.trim().isNotEmpty) {
      payload['languagesSpoken'] = languagesController.text.trim();
    }
    if (badgeNumberController.text.trim().isNotEmpty) {
      payload['badgeNumber'] = badgeNumberController.text.trim();
    }
    if (assignedNumberController.text.trim().isNotEmpty) {
      payload['assignedNumber'] = assignedNumberController.text.trim();
    }
    if (departmentController.text.trim().isNotEmpty) {
      payload['departmentOrPrecinct'] = departmentController.text.trim();
    }
    if (carChangeController.text.trim().isNotEmpty) {
      payload['didCarNumberChange'] = carChangeController.text.trim();
    }
    if (newCarNumberController.text.trim().isNotEmpty) {
      payload['newCarNumber'] = newCarNumberController.text.trim();
    }

    try {
      final response = await authService.register(payload);
      isLoading.value = false;

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200 || statusCode == 201) {
        Helpers.showSuccess(
          'Police account created successfully! Please verify OTP.',
          title: 'Account Created',
        );

        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {
            'flow': 'signup',
            'role': 'POLICE',
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
    badgeNumberController.dispose();
    assignedNumberController.dispose();
    departmentController.dispose();
    carChangeController.dispose();
    newCarNumberController.dispose();
    super.onClose();
  }
}
