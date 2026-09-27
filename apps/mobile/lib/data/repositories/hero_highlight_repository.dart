import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';

class HeroHighlightRepository {
  final ApiClient apiClient;

  HeroHighlightRepository({required this.apiClient});

  /// GET /heroHighlight/officers
  Future<List<Map<String, dynamic>>> getOfficers({String? query}) async {
    try {
      final response = await apiClient.getData(
        ApiConstants.heroHighlightOfficers,
        query: query != null && query.isNotEmpty ? {'query': query} : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['data'];
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// GET /heroHighlight/officers/lookup/:identifier
  Future<Map<String, dynamic>?> lookupOfficer(String identifier) async {
    try {
      final response = await apiClient.getData(
        ApiConstants.heroHighlightLookup(Uri.encodeComponent(identifier)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /heroHighlight
  Future<Map<String, dynamic>?> submitHeroHighlight(Map<String, dynamic> payload) async {
    final response = await apiClient.postData(
      ApiConstants.heroHighlight,
      payload,
    );
    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    return null;
  }

  /// GET /heroHighlight
  Future<List<Map<String, dynamic>>> getHeroHighlights() async {
    try {
      final response = await apiClient.getData(ApiConstants.heroHighlight);
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['data'];
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// PATCH /heroHighlight/:id/salute
  Future<Map<String, dynamic>?> toggleSalute(String highlightId) async {
    try {
      final response = await apiClient.patchData(
        ApiConstants.heroHighlightSalute(highlightId),
        {},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }
}
