import 'dart:async';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/notification_router.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';

class PoliceNotificationController extends GetxController {
  late final NotificationRepository _repo;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  Timer? _pollingTimer;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

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
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
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

  Future<void> onNotificationTapped(NotificationModel notif) async {
    markAsRead(notif);
    await NotificationRouter.navigate(notif);
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true, readAt: DateTime.now());
    }
    notifications.refresh();
    await _repo.markAllAsRead();
    Helpers.showCustomSnackBar('All officer alerts marked as read', type: SnackBarType.success);
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    await _repo.deleteNotification(id);
    Helpers.showCustomSnackBar('Officer alert removed', type: SnackBarType.info);
  }

  static final List<NotificationModel> _defaultNotifications = [
    NotificationModel(
      id: 'pol_notif_1',
      userId: 'police_1',
      type: 'incident',
      title: 'Priority Dispatch: Active Encounter (Marcus Vance)',
      subtitle: 'Citizen requested live legal observation at Elm St & Broadway.',
      resourceType: 'meeting',
      resourceId: 'disp_1',
      isRead: false,
      metadata: {
        'callerName': 'Marcus Vance',
        'location': 'Elm St & Broadway, Precinct 7',
        'category': 'Emergency Stop',
        'isLive': true,
      },
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationModel(
      id: 'pol_notif_2',
      userId: 'police_1',
      type: 'duty',
      title: 'Officer Registry & Duty Roster',
      subtitle: 'New officer duty roster for Precinct 7 has been updated and verified.',
      resourceType: 'roster',
      resourceId: 'rost_1',
      isRead: false,
      metadata: {
        'category': 'Precinct Shift',
      },
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    NotificationModel(
      id: 'pol_notif_3',
      userId: 'police_1',
      type: 'system',
      title: 'Body-Cam & System Security Sweep',
      subtitle: 'Daily encounter encryption and security sweep completed. No anomalies detected.',
      resourceType: 'security',
      resourceId: 'sec_1',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    NotificationModel(
      id: 'pol_notif_4',
      userId: 'police_1',
      type: 'legal',
      title: 'Legal Affairs Office Notice',
      subtitle: 'Quarterly encounter de-escalation documentation deadline is approaching in 5 days.',
      resourceType: 'legal',
      resourceId: 'leg_1',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}

