import 'dart:async';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';
import 'package:gsabino365/core/services/notification_router.dart';

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

  Future<void> onNotificationTapped(NotificationModel notif) async {
    markAsRead(notif);
    await NotificationRouter.navigate(notif);
  }

  static final List<NotificationModel> _defaultNotifications = [
    NotificationModel(
      id: 'notif_1',
      userId: 'user_1',
      type: 'medical',
      title: 'Dr. Sarah Chen',
      subtitle: 'The clinical laboratory results for your consultation are ready for review. Tap to view consultation.',
      resourceType: 'meeting',
      resourceId: 'c1',
      metadata: {
        'callerName': 'Dr. Sarah Chen',
        'topic': 'Telehealth Clinical Review',
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationModel(
      id: 'notif_2',
      userId: 'user_1',
      type: 'legal',
      title: 'Attorney Mark Thompson',
      subtitle: 'New legal consultation request accepted. Tap to view schedule details.',
      resourceType: 'meeting',
      resourceId: 'm1',
      metadata: {
        'callerName': 'Attorney Mark Thompson',
        'topic': 'Legal Representation Consultation',
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'notif_3',
      userId: 'user_1',
      type: 'vault',
      title: '📹 Vault Recording Ready: Incident Session',
      subtitle: 'Your completed session recording has been securely archived. Tap to open Evidence Vault.',
      resourceType: 'recording',
      resourceId: 'rec_1',
      metadata: {
        'topic': 'Traffic Stop Recording',
      },
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'notif_4',
      userId: 'user_1',
      type: 'emergency',
      title: '🛡️ Govia Active Protection Online',
      subtitle: 'Emergency stop button is armed. Responders, video recording, and live GPS are ready.',
      resourceType: 'encounter',
      resourceId: 'enc_1',
      metadata: {
        'category': 'EMERGENCY',
      },
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
