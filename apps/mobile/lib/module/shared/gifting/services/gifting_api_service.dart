import 'package:get/get.dart' hide Response;
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/module/shared/gifting/models/gift_package_model.dart';
import 'package:gsabino365/module/shared/gifting/models/gift_code_model.dart';

class GiftingApiService {
  late final ApiClient _apiClient;

  GiftingApiService({ApiClient? apiClient}) {
    _apiClient = apiClient ??
        (Get.isRegistered<ApiClient>()
            ? Get.find<ApiClient>()
            : Get.put(ApiClient()));
  }

  /// Fetch all configured consumable gift packages
  Future<List<GiftPackageModel>> fetchGiftPackages() async {
    try {
      final response = await _apiClient.getData('/gift-plans/packages');
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData['success'] == true) {
          final List<dynamic> data = resData['data'] ?? [];
          return data.map((json) => GiftPackageModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Purchase gift package via IAP receipt or direct payment
  Future<Map<String, dynamic>?> purchaseGiftPackage({
    required String productId,
    required String provider,
    String? purchaseToken,
    String? transactionId,
  }) async {
    final Map<String, dynamic> payload = {
      'productId': productId,
      'provider': provider,
    };
    if (purchaseToken != null) payload['purchaseToken'] = purchaseToken;
    if (transactionId != null) payload['transactionId'] = transactionId;

    final response = await _apiClient.postData('/gift-plans/purchase', payload);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
    }
    final message = response.data is Map ? response.data['message'] : null;
    throw message ?? 'Failed to purchase gift package';
  }

  /// Fetch all gift codes purchased by the current user with tracking info
  Future<List<GiftCodeModel>> fetchMyPurchasedGifts() async {
    try {
      final response = await _apiClient.getData('/gift-plans/my-purchases');
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        if (resData['success'] == true) {
          final Map<String, dynamic> data = resData['data'] ?? {};
          final List<dynamic> codesList = data['codes'] ?? [];
          return codesList.map((json) => GiftCodeModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Validate a gift code without redeeming it to preview giver & features
  Future<GiftCodePreviewModel> validateGiftCode(String code) async {
    final response = await _apiClient.postData('/gift-plans/validate', {
      'code': code.trim().toUpperCase(),
    });

    if (response.statusCode == 200 &&
        response.data != null &&
        response.data['success'] == true) {
      return GiftCodePreviewModel.fromJson(response.data['data']);
    }
    final message = response.data is Map ? response.data['message'] : null;
    throw message ?? 'Invalid or expired gift code';
  }

  /// Atomically redeem a gift code and activate subscription on recipient account
  Future<Map<String, dynamic>> redeemGiftCode(String code) async {
    final response = await _apiClient.postData('/gift-plans/redeem', {
      'code': code.trim().toUpperCase(),
    });

    if (response.statusCode == 200 &&
        response.data != null &&
        response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    final message = response.data is Map ? response.data['message'] : null;
    throw message ?? 'Unable to redeem this gift code';
  }
}
