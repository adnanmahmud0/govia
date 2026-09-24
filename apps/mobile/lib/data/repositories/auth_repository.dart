import 'package:dio/dio.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';

class AuthRepo {
  final ApiClient apiClient;

  AuthRepo({required this.apiClient});

  /// ===================== LOGIN =====================
  /// POST /auth/login - { email, role, password }
  Future<Response> login({
    required String email,
    required String role,
    required String password,
  }) async {
    return await apiClient.postData(ApiConstants.login, {
      "email": email.trim(),
      "role": role.trim().toUpperCase(),
      "password": password,
    });
  }

  /// ===================== REGISTER =====================
  /// POST /user/register
  Future<Response> register(Map<String, dynamic> data) async {
    return await apiClient.postData(ApiConstants.signup, data);
  }

  /// Backward compatible helper
  Future<Response> signup({
    required String name,
    required String email,
    required String password,
    String? role,
    String? phone,
    String? country,
    Map<String, dynamic>? extraFields,
  }) async {
    final body = <String, dynamic>{
      "name": name.trim(),
      "email": email.trim(),
      "password": password,
      "role": (role ?? "CITIZEN").trim().toUpperCase(),
    };
    if (phone != null && phone.isNotEmpty) body["phoneNumber"] = phone.trim();
    if (extraFields != null) body.addAll(extraFields);
    return await register(body);
  }

  /// ===================== VERIFY EMAIL / OTP =====================
  /// POST /auth/verify-email - { email, role, oneTimeCode }
  Future<Response> verifyEmail({
    required String email,
    required String role,
    required dynamic oneTimeCode,
  }) async {
    final code = oneTimeCode is int
        ? oneTimeCode
        : int.tryParse(oneTimeCode.toString().trim()) ?? oneTimeCode;

    return await apiClient.postData(ApiConstants.verifyEmail, {
      "email": email.trim(),
      "role": role.trim().toUpperCase(),
      "oneTimeCode": code,
    });
  }

  /// Backward-compat alias for verifyEmail
  Future<Response> otpVerify({
    required String email,
    required String otp,
    String? role,
  }) async {
    return await verifyEmail(
      email: email,
      role: role ?? "CITIZEN",
      oneTimeCode: otp,
    );
  }

  /// ===================== RESEND OTP =====================
  /// POST /auth/resend-verify-email - { email, role }
  Future<Response> resendVerifyEmail({
    required String email,
    required String role,
  }) async {
    return await apiClient.postData(ApiConstants.resendVerifyEmail, {
      "email": email.trim(),
      "role": role.trim().toUpperCase(),
    });
  }

  /// Backward-compat alias
  Future<Response> resendOtp({
    required String email,
    String? role,
  }) async {
    return await resendVerifyEmail(
      email: email,
      role: role ?? "CITIZEN",
    );
  }

  /// ===================== FORGOT PASSWORD =====================
  /// POST /auth/forget-password - { email, role }
  Future<Response> forgotPassword({
    required String email,
    required String role,
  }) async {
    return await apiClient.postData(ApiConstants.forgotPassword, {
      "email": email.trim(),
      "role": role.trim().toUpperCase(),
    });
  }

  /// ===================== RESET PASSWORD =====================
  /// POST /auth/reset-password - { newPassword, confirmPassword }
  /// Header: Authorization: Bearer `resetToken`
  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final cleanToken = resetToken.startsWith('Bearer ')
        ? resetToken.substring(7).trim()
        : resetToken.trim();

    return await apiClient.postData(
      ApiConstants.resetPassword,
      {
        "newPassword": newPassword,
        "confirmPassword": confirmPassword,
      },
      extraHeaders: {
        'Authorization': 'Bearer $cleanToken',
      },
    );
  }

  /// ===================== CHANGE PASSWORD =====================
  /// POST /auth/change-password - { currentPassword, newPassword, confirmPassword }
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await apiClient.postData(ApiConstants.changePassword, {
      "currentPassword": currentPassword,
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
    });
  }

  /// ===================== REFRESH TOKEN =====================
  /// POST /auth/refresh - { refreshToken }
  Future<Response> refreshToken(String refreshToken) async {
    return await apiClient.postData(ApiConstants.refreshToken, {
      "refreshToken": refreshToken,
    });
  }

  /// ===================== LOGOUT =====================
  /// POST /auth/logout
  Future<Response> logout({String? deviceToken}) async {
    final body = <String, dynamic>{};
    if (deviceToken != null && deviceToken.isNotEmpty) {
      body["deviceToken"] = deviceToken;
    }
    return await apiClient.postData(ApiConstants.logout, body);
  }
}
