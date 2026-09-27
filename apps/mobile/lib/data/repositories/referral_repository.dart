import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';

class ReferralRepository {
  final ApiClient apiClient;

  ReferralRepository({required this.apiClient});

  /// GET /referral/summary
  Future<Map<String, dynamic>?> getReferralSummary() async {
    final response = await apiClient.getData(ApiConstants.referralSummary);
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return null;
  }

  /// GET /referral/history
  Future<List<Map<String, dynamic>>> getReferralHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiClient.getData(
      ApiConstants.referralHistory,
      query: {'page': page, 'limit': limit},
    );
    if (response.statusCode == 200 && response.data != null) {
      final list = response.data['data'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }

  /// GET /referral/rewards-catalog
  Future<List<Map<String, dynamic>>> getRewardsCatalog() async {
    final response = await apiClient.getData(ApiConstants.referralRewards);
    if (response.statusCode == 200 && response.data != null) {
      final list = response.data['data'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }

  /// POST /referral/redeem
  Future<Map<String, dynamic>?> redeemReward(String rewardId) async {
    final response = await apiClient.postData(
      ApiConstants.referralRedeem,
      {'rewardId': rewardId},
    );
    if (response.statusCode == 200 && response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    return null;
  }

  /// GET /referral/transactions
  Future<List<Map<String, dynamic>>> getPointTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiClient.getData(
      ApiConstants.referralTransactions,
      query: {'page': page, 'limit': limit},
    );
    if (response.statusCode == 200 && response.data != null) {
      final list = response.data['data'];
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }
}
