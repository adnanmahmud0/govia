import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class AttorneyRegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final languagesController = TextEditingController();
  final licensedStatesController = TextEditingController(text: 'Nationwide');
  final barNumberController = TextEditingController();
  final lawFirmController = TextEditingController();
  final officeController = TextEditingController();
  final datePassedBarController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordObscured = true.obs;

  // Dropdown list for Attorney Roles
  final rolesList = [
    'Prosecutor',
    'Defense Attorney',
    'Civil Attorney',
    'Other Attorney',
  ];
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
        Helpers.showError('Please select a role', title: 'Role Required');
        return;
      }

      isLoading.value = true;
      final authService = Get.find<AuthService>();
      final email = emailController.text.trim();

      final payload = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': email,
        'role': 'ATTORNEY',
        'subRole': rxSelectedRole.value,
        'password': passwordController.text,
      };

      if (languagesController.text.trim().isNotEmpty) {
        payload['languagesSpoken'] = languagesController.text.trim();
      }
      if (licensedStatesController.text.trim().isNotEmpty) {
        payload['licensedStatesToPractice'] = licensedStatesController.text.trim();
      }
      if (barNumberController.text.trim().isNotEmpty) {
        payload['barAssociationNumber'] = barNumberController.text.trim();
      }
      if (lawFirmController.text.trim().isNotEmpty) {
        payload['lawFirmName'] = lawFirmController.text.trim();
      }
      if (officeController.text.trim().isNotEmpty) {
        payload['officeName'] = officeController.text.trim();
      }
      if (datePassedBarController.text.trim().isNotEmpty) {
        payload['datePassedTheBar'] = datePassedBarController.text.trim();
      }

      try {
        final response = await authService.register(payload);
        isLoading.value = false;

        final statusCode = response.statusCode ?? 0;
        if (statusCode == 200 || statusCode == 201) {
          Helpers.showSuccess(
            'Attorney account created successfully! Please verify OTP.',
            title: 'Account Created',
          );

          Get.toNamed(
            AppRoutes.otpVerification,
            arguments: {
              'flow': 'signup',
              'role': 'ATTORNEY',
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
    passwordController.dispose();
    languagesController.dispose();
    licensedStatesController.dispose();
    barNumberController.dispose();
    lawFirmController.dispose();
    officeController.dispose();
    datePassedBarController.dispose();
    super.onClose();
  }
}
