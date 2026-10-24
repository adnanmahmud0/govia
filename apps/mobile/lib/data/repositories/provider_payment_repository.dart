import 'package:dio/dio.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/models/provider_directory_item.dart';

class ProviderPaymentRepository {
  final ApiClient apiClient;
  String? lastErrorMessage;

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

  /// GET /provider-payment/service-charge
  Future<Map<String, dynamic>?> getServiceChargeSettings() async {
    try {
      final response = await apiClient.getData(ApiConstants.providerServiceCharge);
      if (response.statusCode == 200 && response.data?['data'] != null) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  /// POST /provider-payment/service-checkout
  Future<Map<String, dynamic>?> createServiceCheckoutSession({
    required String role,
    String? providerId,
  }) async {
    lastErrorMessage = null;
    final payload = <String, dynamic>{
      'role': role,
    };
    if (providerId != null && providerId.isNotEmpty) {
      payload['providerId'] = providerId;
    }
    final response = await apiClient.postData(
      ApiConstants.providerServiceCheckout,
      payload,
    );
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    lastErrorMessage = response.data?['message']?.toString() ??
        'Failed to initialize service checkout session.';
    return null;
  }

  /// POST /provider-payment/select-preferred
  Future<Map<String, dynamic>?> selectPreferredProvider({
    required String providerId,
    required String role,
  }) async {
    lastErrorMessage = null;
    final response = await apiClient.postData(
      ApiConstants.providerSelectPreferred,
      {
        'providerId': providerId,
        'role': role,
      },
    );
    if (response.statusCode == 200 && response.data != null) {
      return response.data['data'] != null
          ? Map<String, dynamic>.from(response.data['data'])
          : <String, dynamic>{};
    }
    lastErrorMessage = response.data?['message']?.toString() ??
        'Could not link preferred provider.';
    return null;
  }

  /// GET /provider-payment/pricing-profile
  Future<Map<String, dynamic>?> getPricingProfile() async {
    final response = await apiClient.getData(ApiConstants.providerPricingProfile);
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  /// PATCH /provider-payment/pricing-profile
  Future<Response> updatePricingProfile({
    double? serviceFee,
    double? monthlyServiceFee,
    String? shortDescription,
  }) async {
    final data = <String, dynamic>{};
    if (shortDescription != null) data['shortDescription'] = shortDescription;

    final res = await apiClient.patchData(ApiConstants.providerPricingProfile, data);
    if (res.statusCode != 200) {
      return await apiClient.putData(ApiConstants.providerPricingProfile, data);
    }
    return res;
  }

  /// POST /provider-payment/checkout-session (Backward-compatible)
  Future<Map<String, dynamic>?> createCheckoutSession(String providerId, {String? role}) async {
    final payload = <String, dynamic>{'providerId': providerId};
    if (role != null) payload['role'] = role;
    final response = await apiClient.postData(
      ApiConstants.providerCheckoutSession,
      payload,
    );
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  /// POST /provider-payment/verify-session
  Future<Map<String, dynamic>?> verifySession(String sessionId) async {
    final response = await apiClient.getData(
      '${ApiConstants.providerVerifySession}/$sessionId',
    );
    if (response.statusCode == 200 && response.data?['data'] != null) {
      return Map<String, dynamic>.from(response.data['data']);
    }
    return null;
  }

  // Deprecated payout stubs
  Future<Map<String, dynamic>?> createPayoutAccount() async => null;
  Future<Map<String, dynamic>?> getPayoutStatus() async => {'payoutsEnabled': false};
  Future<String?> getPayoutDashboardLink() async => null;
}
