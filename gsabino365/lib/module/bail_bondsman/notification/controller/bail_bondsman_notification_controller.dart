import 'dart:async';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';

class BailBondsmanNotificationController extends GetxController {
  late final NotificationRepository _repo;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'All'.obs; // 'All', 'Unread'
  Timer? _pollingTimer;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get filteredNotifications {
    if (selectedFilter.value == 'Unread') {
      return notifications.where((n) => !n.isRead).toList();
    }
    return notifications;
  }

  @override
  void onInit() {
    super.onInit();
    _repo = NotificationRepository(apiClient: Get.find<ApiClient>());
    fetchNotifications();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchNotifications(silent: true);
    });
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
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
      id: 'bb_notif_1',
      userId: 'bb_user',
      type: 'legal',
      title: 'Bond Processing Update',
      subtitle: 'Active collateral and bond permission mappings for Client #7734 have been verified.',
      resourceType: 'bond',
      resourceId: 'b7734',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    NotificationModel(
      id: 'bb_notif_2',
      userId: 'bb_user',
      type: 'legal',
      title: 'Indemnitor Alert',
      subtitle: 'New indemnitor submission from Mark Allen is awaiting co-signature review.',
      resourceType: 'indemnitor',
      resourceId: 'i102',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'bb_notif_3',
      userId: 'bb_user',
      type: 'system',
      title: 'System Reconciliation',
      subtitle: 'Daily surety reconciliation report has been generated and filed successfully.',
      resourceType: 'report',
      resourceId: 'r44',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      id: 'bb_notif_4',
      userId: 'bb_user',
      type: 'court',
      title: 'Court Registry Alert',
      subtitle: 'Pre-trial appearance scheduled for Case #2209 at Ohio Municipal Court.',
      resourceType: 'court',
      resourceId: 'c2209',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
