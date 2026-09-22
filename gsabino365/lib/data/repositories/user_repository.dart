import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/models/user_model.dart';

class UserRepository {
  final ApiClient apiClient;

  UserRepository({required this.apiClient});

  /// GET /user/profile - Fetch the currently authenticated user's profile
  Future<Response> getProfile() async {
    return await apiClient.getData(ApiConstants.profile);
  }

  /// PATCH /user/profile - Update the authenticated user's profile
  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await apiClient.patchData(ApiConstants.profile, data);
  }

  /// PATCH /user/profile - Update profile with multipart data (e.g. image file)
  Future<Response> updateProfileMultipart(
    Map<String, dynamic> data, {
    File? imageFile,
  }) async {
    final multipartList = <MultipartBody>[];
    if (imageFile != null) {
      multipartList.add(MultipartBody('image', imageFile));
    }
    if (multipartList.isNotEmpty) {
      return await apiClient.patchMultipartData(
        ApiConstants.profile,
        data,
        multipartBody: multipartList,
      );
    } else {
      return await apiClient.patchData(ApiConstants.profile, data);
    }
  }

  /// Parses profile response into UserModel
  UserModel? parseUser(Response response) {
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data['data'] ?? response.data;
      if (data is Map<String, dynamic>) {
        return UserModel.fromJson(data);
      }
    }
    return null;
  }
}
