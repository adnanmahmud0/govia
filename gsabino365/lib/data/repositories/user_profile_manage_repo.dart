/*
import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../services/api_client.dart';

class UserProfileManageRepo {
  final ApiClient apiClient;
  UserProfileManageRepo({required this.apiClient});

  /// ===================== GET PROFILE =====================
  Future<Response> getProfile() async {
    return await apiClient.getData(ApiEndpoints.getProfile);
  }

  /// ===================== GET PROFILE =====================
  Future<Response> getChildrenProfile() async {
    return await apiClient.getData(ApiEndpoints.getChildrenProfile);
  }

  /// ===================== CREATE Child PROFILE =====================
  Future<Response> createChildrenProfile(Map<String, dynamic> body) async {
    return await apiClient.postData(ApiEndpoints.getChildrenProfile, body);
  }

  /// ===================== UPDATE PROFILE =====================
  Future<Response> updateProfile(Map<String, dynamic> body) async {
    return await apiClient.patchData(ApiEndpoints.updateProfile, body);
  }

  /// ===================== UPDATE PROFILE image =====================
  Future<Response> updateProfileImage(dynamic body) async {
    return await apiClient.patchData(ApiEndpoints.updateProfile, body);
  }

  /// ===================== UPDATE PROFILE =====================
  Future<Response> updateChildProfile(
    String childId,
    Map<String, dynamic> body,
  ) async {
    return await apiClient.patchData(
      ApiEndpoints.updateChildProfile(childId: childId),
      body,
    );
  }

  /// ===================== UPDATE PROFILE image =====================
  Future<Response> updateChildProfileImage(String childId, dynamic body) async {
    return await apiClient.patchData(
      ApiEndpoints.updateChildProfile(childId: childId),
      body,
    );
  }

  /// ===================== Create child PROFILE  =====================
  Future<Response> createChildProfile(dynamic body) async {
    return await apiClient.postData(ApiEndpoints.createChildProfile, body);
  }

  /// ===================== create child  PROFILE image =====================
  Future<Response> createChildProfileImage(dynamic body) async {
    return await apiClient.postData(ApiEndpoints.createChildProfile, body);
  }
}
*/
