import 'dart:async';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';
import 'package:gsabino365/core/services/notification_router.dart';

class AttorneyNotificationController extends GetxController {
  late final NotificationRepository _repo;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  Timer? _pollingTimer;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    final apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : Get.put(ApiClient());
    _repo = NotificationRepository(apiClient: apiClient);
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
    Helpers.showSuccess('All notifications marked as read');
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    await _repo.deleteNotification(id);
    Helpers.showSuccess('Notification removed');
  }

  static final List<NotificationModel> _defaultNotifications = [
    NotificationModel(
      id: 'atty_notif_1',
      userId: 'atty_1',
      type: 'legal',
      title: '⚖️ Emergency Defense: Marcus Vance',
      subtitle: 'Citizen Marcus Vance requested emergency legal defense during a police stop at Elm St & Broadway. Tap to review & join call.',
      resourceType: 'meeting',
      resourceId: 'meeting_demo_1',
      metadata: {
        'callerName': 'Marcus Vance',
        'callerRole': 'CITIZEN',
        'location': 'Elm St & Broadway',
        'category': 'EMERGENCY',
        'isLive': true,
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    NotificationModel(
      id: 'atty_notif_2',
      userId: 'atty_1',
      type: 'consultation',
      title: '📅 Client Legal Consultation: Sarah Jenkins',
      subtitle: 'Pre-trial consultation scheduled with client Sarah Jenkins. Tap to view schedule details.',
      resourceType: 'meeting',
      resourceId: 'case_4821',
      metadata: {
        'callerName': 'Sarah Jenkins',
        'topic': 'Pre-trial Hearing Preparation',
        'isLive': false,
      },
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'atty_notif_3',
      userId: 'atty_1',
      type: 'vault',
      title: '📁 Evidence Vault & Case Files',
      subtitle: 'Review client encounter video recordings and verified witness statements in Evidence Vault.',
      resourceType: 'vault',
      resourceId: 'vault_case_3311',
      metadata: {
        'folderName': 'Client Encounter Files',
      },
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'atty_notif_4',
      userId: 'atty_1',
      type: 'compliance',
      title: '🏛️ Bar Defense Verification Active',
      subtitle: 'Your active bar credentials have been verified for expedited legal representation.',
      resourceType: 'system',
      resourceId: 'audit_2026',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
