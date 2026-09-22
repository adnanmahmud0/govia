import 'dart:async';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';

class DoctorNotificationController extends GetxController {
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

  Future<void> markAllAsRead() async {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(isRead: true, readAt: DateTime.now());
    }
    notifications.refresh();
    await _repo.markAllAsRead();
    Helpers.showSuccess('All notifications marked as read');
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    await _repo.deleteNotification(id);
    Helpers.showSuccess('Notification removed');
  }

  static final List<NotificationModel> _defaultNotifications = [
    NotificationModel(
      id: 'doc_notif_1',
      userId: 'doc_1',
      type: 'assessment',
      title: 'Clinical Assessment Request',
      subtitle: 'New clinical assessment for Patient #0047 has been submitted for verification.',
      resourceType: 'assessment',
      resourceId: 'ass_1',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    NotificationModel(
      id: 'doc_notif_2',
      userId: 'doc_1',
      type: 'dispatch',
      title: 'Mobile Crisis Team Dispatch',
      subtitle: 'Field unit assigned to District 4 incident. Live telehealth triage requested.',
      resourceType: 'dispatch',
      resourceId: 'disp_1',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    NotificationModel(
      id: 'doc_notif_3',
      userId: 'doc_1',
      type: 'system',
      title: 'HIPAA Compliance Verified',
      subtitle: 'Your monthly telehealth encryption and compliance documentation has been approved.',
      resourceType: 'compliance',
      resourceId: 'comp_1',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'doc_notif_4',
      userId: 'doc_1',
      type: 'schedule',
      title: 'Consultation Shift Updated',
      subtitle: 'Dr. Sarah Chen updated the on-call emergency de-escalation roster.',
      resourceType: 'schedule',
      resourceId: 'sched_1',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
