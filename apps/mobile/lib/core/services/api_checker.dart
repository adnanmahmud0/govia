import 'package:dio/dio.dart';
import 'package:gsabino365/core/utils/helpers.dart';

/// ===================== API CHECKER =====================
/// Utility to inspect API responses and surface errors appropriately.
/// - GET errors → debug log only (non-intrusive)
/// - WRITE errors → user-facing snackbar
class ApiChecker {
  ApiChecker._();

  /// Check GET response — logs errors silently
  static void checkGetApi(Response response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode == 401) return; // Handled by interceptor

    if (statusCode < 200 || statusCode >= 300) {
      final message = _extractMessage(response, fallback: 'Request failed');
      Helpers.debug('GET API ERROR => $message');
    }
  }

  /// Check WRITE (POST/PUT/PATCH/DELETE) response — shows user snackbar
  static void checkWriteApi(Response response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode == 401) return; // Handled by interceptor

    if (statusCode < 200 || statusCode >= 300) {
      final message = _extractMessage(response, fallback: 'Operation failed');
      Helpers.showError(message);
    }
  }

  /// Extract error message from response data
  static String _extractMessage(Response response, {required String fallback}) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return response.statusMessage ?? fallback;
  }
}
