import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class OtpVerificationController extends GetxController {
  late final String email;
  late final String flow;
  late final String role;

  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();
  final RxString otpCode = ''.obs;
  final RxBool isOtpFocused = false.obs;

  final RxInt timerSeconds = 30.obs;
  Timer? _timer;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      email = args['email']?.toString().trim() ?? '';
      flow = args['flow']?.toString() ?? 'signup';
      role = (args['role']?.toString() ?? 'CITIZEN').toUpperCase();
    } else {
      email = args is String ? args.trim() : '';
      flow = 'signup';
      role = 'CITIZEN';
    }

    otpController.addListener(() {
      otpCode.value = otpController.text;
    });

    otpFocusNode.addListener(() {
      isOtpFocused.value = otpFocusNode.hasFocus;
    });

    startTimer();
  }

  void startTimer() {
    timerSeconds.value = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  String get formattedTimer {
    final seconds = timerSeconds.value.toString().padLeft(2, '0');
    return '00:$seconds';
  }

  Future<void> resendOtp() async {
    if (timerSeconds.value > 0) return;

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      final response = await authService.resendOtp(
        email: email,
        role: role,
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200 || statusCode == 201) {
        Helpers.showSuccess(
          'Verification code resent to your email.',
          title: 'Code Sent',
        );
        otpController.clear();
        startTimer();
      } else {
        final message = response.statusMessage ??
            (response.data is Map ? response.data['message']?.toString() : null) ??
            'Failed to resend code.';
        Helpers.showError(message, title: 'Error');
      }
    } catch (e) {
      Helpers.showError('Could not resend verification code. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final code = otpController.text.trim();
    if (code.length < 4) {
      Helpers.showError('Please enter the complete 4-digit OTP code.');
      return;
    }

    isLoading.value = true;
    final authService = Get.find<AuthService>();

    try {
      final response = await authService.verifyEmailOtp(
        email: email,
        role: role,
        oneTimeCode: code,
      );

      final statusCode = response.statusCode ?? 0;
      final data = response.data;
      final message = (data is Map ? data['message']?.toString() : null) ??
          response.statusMessage ??
          'Verification successful';

      if (statusCode == 200 || statusCode == 201) {
        Helpers.showSuccess(message, title: 'Verified');

        if (flow == 'forgot_password') {
          // Govia returns createToken in data
          final resetToken = (data is Map && data['data'] != null)
              ? data['data'].toString()
              : '';

          Get.offNamed(
            AppRoutes.resetPassword,
            arguments: resetToken,
          );
        } else {
          // Signup or unverified login flow: redirect to login
          Get.offAllNamed(AppRoutes.login);
        }
      } else {
        Helpers.showError(message, title: 'Verification Failed');
      }
    } catch (e) {
      Helpers.showError('Verification failed. Please check the code and try again.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    super.onClose();
  }
}
