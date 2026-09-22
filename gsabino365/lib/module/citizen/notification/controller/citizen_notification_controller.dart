import 'dart:async';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';

class CitizenNotificationController extends GetxController {
  late final NotificationRepository _repo;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs; // 'All', 'Unread', 'Legal', 'Medical', 'System'
  Timer? _pollingTimer;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get filteredNotifications {
    if (selectedFilter.value == 'Unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else if (selectedFilter.value != 'All') {
      return notifications
          .where((n) => n.type.toLowerCase() == selectedFilter.value.toLowerCase())
          .toList();
    }
    return notifications;
  }

  @override
  void onInit() {
    super.onInit();
    _repo = NotificationRepository(apiClient: Get.find<ApiClient>());
    fetchNotifications();
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchNotifications(silent: true);
    });
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final res = await _repo.getNotifications();
      if (res != null && res.data.isNotEmpty) {
        notifications.assignAll(res.data);
      } else if (notifications.isEmpty) {
        notifications.assignAll(_defaultNotifications);
      }
    } catch (_) {
      if (notifications.isEmpty) {
        notifications.assignAll(_defaultNotifications);
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> markAsRead(NotificationModel notif) async {
    if (notif.isRead) return;
    final index = notifications.indexWhere((n) => n.id == notif.id);
    if (index != -1) {
      notifications[index] = notif.copyWith(isRead: true, readAt: DateTime.now());
      notifications.refresh();
    }
    await _repo.markAsRead(notif.id);
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true, readAt: DateTime.now());
    }
    notifications.refresh();
    await _repo.markAllAsRead();
    Helpers.showCustomSnackBar('All notifications marked as read', type: SnackBarType.success);
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    await _repo.deleteNotification(id);
    Helpers.showCustomSnackBar('Notification removed', type: SnackBarType.info);
  }

  static final List<NotificationModel> _defaultNotifications = [
    NotificationModel(
      id: 'notif_1',
      userId: 'user_1',
      type: 'medical',
      title: 'Dr. Sarah Chen',
      subtitle: 'The clinical laboratory results for your consultation are ready for review.',
      resourceType: 'consultation',
      resourceId: 'c1',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationModel(
      id: 'notif_2',
      userId: 'user_1',
      type: 'legal',
      title: 'Attorney Mark Thompson',
      subtitle: 'New legal consultation request accepted. View details in your sessions.',
      resourceType: 'meeting',
      resourceId: 'm1',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'notif_3',
      userId: 'user_1',
      type: 'system',
      title: 'System Security Alert',
      subtitle: 'Emergency recording and location telemetry are active on your device.',
      resourceType: 'system',
      resourceId: 's1',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'notif_4',
      userId: 'user_1',
      type: 'info',
      title: 'GoVia Emergency AI',
      subtitle: 'Safety profile updated. Your preferred emergency providers have been notified.',
      resourceType: 'profile',
      resourceId: 'p1',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
