import 'package:flutter/foundation.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/data/models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /notification or /notification/my-notifications
  Future<NotificationResponse?> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.getData(
        '/notification',
        query: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // Check standard response wrapper
          if (data.containsKey('data')) {
            if (data['data'] is List) {
              final list = (data['data'] as List)
                  .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList();
              final unread = list.where((n) => !n.isRead).length;
              return NotificationResponse(
                data: list,
                meta: NotificationMeta(
                  limit: limit,
                  hasMore: list.length >= limit,
                  unreadCount: unread,
                ),
              );
            } else if (data['data'] is Map) {
              return NotificationResponse.fromJson(
                Map<String, dynamic>.from(data['data'] as Map),
              );
            }
          }
          return NotificationResponse.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error fetching notifications: $e');
      return null;
    }
  }

  /// PATCH /notification/:id/read or POST /notification/:id/read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.patchData(
        '/notification/$notificationId/read',
        {},
      );
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await _apiClient.postData(
          '/notification/$notificationId/read',
          {},
        );
        return response.statusCode == 200;
      } catch (e) {
        debugPrint('⚠️ Error marking notification as read: $e');
        return false;
      }
    }
  }

  /// PATCH /notification/read-all
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.patchData(
        '/notification/read-all',
        {},
      );
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await _apiClient.postData(
          '/notification/read-all',
          {},
        );
        return response.statusCode == 200;
      } catch (e) {
        debugPrint('⚠️ Error marking all notifications as read: $e');
        return false;
      }
    }
  }

  /// DELETE /notification/:id
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiClient.deleteData(
        '/notification/$notificationId',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Error deleting notification: $e');
      return false;
    }
  }
}
