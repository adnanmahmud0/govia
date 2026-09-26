import 'dart:io';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'package:gsabino365/config/constants/storage_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/storage_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/user_model.dart';
import 'package:gsabino365/data/repositories/auth_repository.dart';
import 'package:gsabino365/data/repositories/user_repository.dart';

class AuthResult {
  final bool success;
  final bool isUnverified;
  final String? email;
  final String? role;
  final String? message;
  final dynamic data;

  AuthResult({
    required this.success,
    this.isUnverified = false,
    this.email,
    this.role,
    this.message,
    this.data,
  });
}

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  late AuthRepo _authRepo;
  late UserRepository _userRepo;

  // Reactive state
  final isLoggedIn = false.obs;
  final currentUser = Rx<UserModel?>(null);
  final currentRole = ''.obs;

  bool get isAuthenticated => isLoggedIn.value;

  @override
  void onInit() {
    super.onInit();
    final client = Get.find<ApiClient>();
    _authRepo = AuthRepo(apiClient: client);
    _userRepo = UserRepository(apiClient: client);

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await StorageService.getString(StorageConstants.bearerToken);
    final savedRole = await StorageService.getString(StorageConstants.userRole);
    isLoggedIn.value = token.isNotEmpty;
    currentRole.value = savedRole;

    // Instantly hydrate cached user profile if present
    final cachedUserData = await StorageService.getMap(StorageConstants.userData);
    if (cachedUserData.isNotEmpty) {
      try {
        currentUser.value = UserModel.fromJson(cachedUserData);
      } catch (e) {
        Helpers.debug('Error hydrating cached user profile: $e');
      }
    }
  }

  Future<AuthService> init() async {
    return this;
  }

  // ──────────────────────── LOGIN ────────────────────────

  /// Real login to POST /auth/login
  Future<AuthResult> login({
    required String email,
    required String role,
    required String password,
  }) async {
    try {
      final response = await _authRepo.login(
        email: email,
        role: role,
        password: password,
      );

      final statusCode = response.statusCode ?? 0;
      final data = response.data;
      final message = response.statusMessage ??
          (data is Map ? data['message']?.toString() : null) ??
          '';

      // Check if account is unverified (status 400 with unverified notice)
      if (statusCode == 400 &&
          (message.toLowerCase().contains('verify your account') ||
              message.toLowerCase().contains('not verified'))) {
        // Auto-trigger resend OTP for developer/user convenience
        try {
          await _authRepo.resendVerifyEmail(email: email, role: role);
        } catch (_) {}

        return AuthResult(
          success: false,
          isUnverified: true,
          email: email,
          role: role,
          message: message,
        );
      }

      if (statusCode == 200 || statusCode == 201) {
        await _handleAuthSuccess(response, role);
        // Fetch full profile
        await fetchProfile();
        final finalRole = currentUser.value?.role ?? role;
        return AuthResult(
          success: true,
          role: finalRole,
          message: message.isNotEmpty ? message : 'Logged in successfully',
          data: data,
        );
      }

      return AuthResult(
        success: false,
        message: message.isNotEmpty ? message : 'Login failed ($statusCode)',
      );
    } catch (e) {
      Helpers.debug('AuthService login error: $e');
      return AuthResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ──────────────────────── REGISTER ────────────────────────

  Future<Response> register(Map<String, dynamic> data) async {
    try {
      final response = await _authRepo.register(data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Backward compatible registration helper
  Future<Response> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? country,
    String? role,
    Map<String, dynamic>? extraFields,
  }) async {
    try {
      final response = await _authRepo.signup(
        name: name,
        email: email,
        password: password,
        phone: phone,
        country: country,
        role: role,
        extraFields: extraFields,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────── OTP / VERIFICATION ────────────────────────

  Future<Response> verifyEmailOtp({
    required String email,
    required String role,
    required dynamic oneTimeCode,
  }) async {
    try {
      final response = await _authRepo.verifyEmail(
        email: email,
        role: role,
        oneTimeCode: oneTimeCode,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> verifyOtp({
    required String email,
    required String otp,
    String? role,
  }) async {
    return await verifyEmailOtp(
      email: email,
      role: role ?? currentRole.value.ifEmpty('CITIZEN'),
      oneTimeCode: otp,
    );
  }

  Future<Response> resendOtp({
    required String email,
    required String role,
  }) async {
    try {
      final response = await _authRepo.resendVerifyEmail(
        email: email,
        role: role,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────── FORGOT & RESET PASSWORD ────────────────────────

  Future<Response> forgotPassword({
    required String email,
    required String role,
  }) async {
    try {
      final response = await _authRepo.forgotPassword(
        email: email,
        role: role,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _authRepo.resetPassword(
        resetToken: resetToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _authRepo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ──────────────────────── PROFILE & SESSION RESTORE ────────────────────────

  Future<UserModel?> fetchProfile() async {
    try {
      final response = await _userRepo.getProfile();
      if (response.statusCode == 200 && response.data != null) {
        final user = _userRepo.parseUser(response);
        if (user != null) {
          currentUser.value = user;
          await StorageService.setMap(
            StorageConstants.userData,
            user.toJson(),
          );
          if (user.role != null && user.role!.isNotEmpty) {
            currentRole.value = user.role!;
            await StorageService.setString(
              StorageConstants.userRole,
              user.role!,
            );
          }
          return user;
        }
      }
    } catch (e) {
      Helpers.debug('Error fetching user profile: $e');
    }
    return null;
  }

  /// Alias for fetchProfile for backward/forward compatibility
  Future<UserModel?> getProfile() => fetchProfile();

  /// Updates profile on backend and synchronizes currentUser reactive state
  Future<UserModel?> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _userRepo.updateProfile(data);
      if (response.statusCode == 200 && response.data != null) {
        final user = _userRepo.parseUser(response);
        if (user != null) {
          currentUser.value = user;
          await StorageService.setMap(
            StorageConstants.userData,
            user.toJson(),
          );
          return user;
        }
      }
    } catch (e) {
      Helpers.debug('Error updating user profile: $e');
    }
    return null;
  }

  /// Uploads profile image via multipart PATCH /user/profile and updates currentUser
  Future<UserModel?> updateProfileImage(File imageFile) async {
    try {
      final response = await _userRepo.updateProfileMultipart(
        {},
        imageFile: imageFile,
      );
      if (response.statusCode == 200 && response.data != null) {
        final user = _userRepo.parseUser(response);
        if (user != null) {
          currentUser.value = user;
          await StorageService.setMap(
            StorageConstants.userData,
            user.toJson(),
          );
          return user;
        }
      }
    } catch (e) {
      Helpers.debug('Error updating profile image: $e');
    }
    return null;
  }

  /// Restores session from stored token and validates via GET /user/profile
  Future<bool> restoreSession() async {
    final token = await StorageService.getString(StorageConstants.bearerToken);
    if (token.isEmpty) {
      isLoggedIn.value = false;
      return false;
    }

    final savedRole = await StorageService.getString(StorageConstants.userRole);
    if (savedRole.isNotEmpty) {
      currentRole.value = savedRole;
    }

    final user = await fetchProfile();
    if (user != null) {
      isLoggedIn.value = true;
      return true;
    }

    // Token might be invalid or expired
    final hasToken = await StorageService.getString(StorageConstants.bearerToken);
    if (hasToken.isNotEmpty) {
      isLoggedIn.value = true;
      return true;
    }

    isLoggedIn.value = false;
    return false;
  }

  // ──────────────────────── LOGOUT ────────────────────────

  Future<void> logout() async {
    // Suppress any 401s that race-fire from controllers still alive during navigation
    ApiClient.markLoggingOut();
    try {
      await _authRepo.logout();
    } catch (_) {
      // Ignore network failures on logout
    } finally {
      await _clearLocalAuth();
      Get.offAllNamed(AppRoutes.login);
      // Reset the guard after navigation so next login session is unaffected
      Future.delayed(const Duration(seconds: 3), ApiClient.clearLoggingOut);
    }
  }

  // ──────────────────────── HELPERS ────────────────────────

  Future<void> _handleAuthSuccess(Response response, String role) async {
    final data = response.data;
    if (data is! Map) return;

    final authData = data['data'] is Map ? data['data'] : data;
    final String? accessToken = authData['accessToken'] ?? authData['token'];
    final String? refreshToken = authData['refreshToken'];

    if (accessToken != null && accessToken.isNotEmpty) {
      await StorageService.setString(StorageConstants.bearerToken, accessToken);
      isLoggedIn.value = true;
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await StorageService.setString(
        StorageConstants.refreshToken,
        refreshToken,
      );
    }

    currentRole.value = role.toUpperCase();
    await StorageService.setString(
      StorageConstants.userRole,
      role.toUpperCase(),
    );
  }

  Future<void> _clearLocalAuth() async {
    await StorageService.remove(StorageConstants.bearerToken);
    await StorageService.remove(StorageConstants.refreshToken);
    await StorageService.remove(StorageConstants.userData);
    await StorageService.remove(StorageConstants.userRole);
    await StorageService.remove(StorageConstants.resetToken);

    currentUser.value = null;
    currentRole.value = '';
    isLoggedIn.value = false;
  }
}

extension StringExtension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
