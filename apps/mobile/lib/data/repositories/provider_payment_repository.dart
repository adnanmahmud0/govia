import 'package:dio/dio.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/models/provider_directory_item.dart';

class ProviderPaymentRepository {
  final ApiClient apiClient;

  ProviderPaymentRepository({required this.apiClient});

  /// GET /provider/directory
  Future<List<ProviderDirectoryItem>> getProviderDirectory({
    String? role,
    String? state,
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await apiClient.getData(
      ApiConstants.providerDirectory,
      query: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      final rawList = response.data['data'];
      if (rawList is List) {
        return rawList
            .map((item) => ProviderDirectoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// GET /provider-payment/pricing-profile
  Future<Map<String, dynamic>?> getPricingProfile() async {
    final response = await apiClient.getData(ApiConstants.providerPricingProfile);
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  /// PUT /provider-payment/pricing-profile
  Future<Response> updatePricingProfile({
    double? serviceFee,
    double? monthlyServiceFee,
    String? shortDescription,
  }) async {
    final data = <String, dynamic>{};
    if (serviceFee != null) data['serviceFee'] = serviceFee;
    if (monthlyServiceFee != null) data['monthlyServiceFee'] = monthlyServiceFee;
    if (shortDescription != null) data['shortDescription'] = shortDescription;

    return await apiClient.putData(ApiConstants.providerPricingProfile, data);
  }

  /// POST /provider-payment/payout-account
  Future<Map<String, dynamic>?> createPayoutAccount() async {
    final response = await apiClient.postData(ApiConstants.providerPayoutAccount, {});
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  /// GET /provider-payment/payout-status
  Future<Map<String, dynamic>?> getPayoutStatus() async {
    final response = await apiClient.getData(ApiConstants.providerPayoutStatus);
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  /// GET /provider-payment/payout-dashboard
  Future<String?> getPayoutDashboardLink() async {
    final response = await apiClient.getData(ApiConstants.providerPayoutDashboard);
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return response.data['data']['url']?.toString();
    }
    return null;
  }

  /// POST /provider-payment/checkout-session
  Future<Map<String, dynamic>?> createCheckoutSession(String providerId) async {
    final response = await apiClient.postData(
      ApiConstants.providerCheckoutSession,
      {'providerId': providerId},
    );
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  /// POST /provider-payment/verify-session
  Future<Map<String, dynamic>?> verifySession(String sessionId) async {
    final response = await apiClient.postData(
      ApiConstants.providerVerifySession,
      {'sessionId': sessionId},
    );
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }
}
