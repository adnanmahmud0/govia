import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';
import 'package:gsabino365/module/bail_bondsman/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';

class BailBondsmanHomeController extends GetxController {
  final RxString activeRole = 'Bail Bondsman'.obs;

  MeetingRepository? _meetingRepo;
  NotificationRepository? _notifRepo;
  Timer? _refreshTimer;

  final RxInt liveIncidentsCount = 0.obs;
  final RxInt upcomingScheduleCount = 0.obs;
  final RxInt unreadNotificationsCount = 0.obs;
  final RxBool isLoading = false.obs;

  AuthService get _authService => Get.find<AuthService>();

  String get userName {
    if (Get.isRegistered<AuthService>()) {
      final name = _authService.currentUser.value?.name?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'Dana Morgan';
  }

  String get avatarUrl {
    if (Get.isRegistered<AuthService>()) {
      final user = _authService.currentUser.value;
      final img = user?.image ?? user?.profilePicture;
      if (img != null && img.isNotEmpty) return ApiConstants.getFileUrl(img);
    }
    return '';
  }

  String get userRole => 'Bail Bondsman';

  String get licenseNumber {
    if (Get.isRegistered<AuthService>()) {
      final user = _authService.currentUser.value;
      final lic = user?.licenseNumber?.trim();
      if (lic != null && lic.isNotEmpty) return lic;
      final assigned = user?.assignedNumber?.trim();
      if (assigned != null && assigned.isNotEmpty) return assigned;
    }
    return 'BB-882910';
  }

  String get shortHexId {
    if (Get.isRegistered<AuthService>()) {
      final user = _authService.currentUser.value;
      if (user?.shortHexId != null && user!.shortHexId!.isNotEmpty) {
        return user.shortHexId!;
      }
      final id = user?.id?.trim() ?? '';
      if (id.length >= 8) {
        return id.substring(id.length - 8).toUpperCase();
      } else if (id.isNotEmpty) {
        return id.toUpperCase();
      }
    }
    return '882910BB';
  }

  String get fullId {
    if (Get.isRegistered<AuthService>()) {
      return _authService.currentUser.value?.id?.trim() ?? licenseNumber;
    }
    return licenseNumber;
  }

  void openQrDialog({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: userName,
      userRole: userRole,
      shortHexId: shortHexId,
      fullId: fullId,
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrScanner() => openQrDialog(initialTabIndex: 1);

  void copyHexId() {
    final hexId = shortHexId;
    Clipboard.setData(ClipboardData(text: hexId));
    Get.rawSnackbar(
      message: 'Copied Short Hex ID: #$hexId',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1550A6),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<ApiClient>()) {
      final client = Get.find<ApiClient>();
      _meetingRepo = MeetingRepository(apiClient: client);
      _notifRepo = NotificationRepository(apiClient: client);
      refreshDashboardData();
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        refreshDashboardData(silent: true);
      });
    }
  }

  Future<void> refreshDashboardData({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      // 1. Fetch active emergency requests / incidents
      if (_meetingRepo != null) {
        final activeMeetings = await _meetingRepo!.getActiveMeetings();
        liveIncidentsCount.value = activeMeetings.length;
      }

      // 2. Fetch upcoming schedule count from backend
      if (Get.isRegistered<ApiClient>()) {
        final client = Get.find<ApiClient>();
        final res = await client.getData(ApiConstants.myMeetings);
        if (res.statusCode == 200 && res.data != null) {
          final rawData = res.data['data'];
          List items = [];
          if (rawData is List) {
            items = rawData;
          } else if (rawData is Map && rawData['data'] is List) {
            items = rawData['data'] as List;
          }
          final upcoming = items.where((m) {
            final status = m['status']?.toString().toUpperCase() ?? 'SCHEDULED';
            final type = (m['meetingType'] ?? '').toString().toUpperCase();
            final cat = (m['category'] ?? '').toString().toUpperCase();
            if (type == 'EMERGENCY' || cat == 'EMERGENCY' || cat == 'ENCOUNTER') return false;
            return status == 'SCHEDULED' || status == 'ACTIVE';
          }).length;
          upcomingScheduleCount.value = upcoming;
        }
      }

      // 3. Fetch unread notifications count
      if (_notifRepo != null) {
        final notifs = await _notifRepo!.getNotifications(page: 1, limit: 10);
        if (notifs != null) {
          unreadNotificationsCount.value = notifs.meta.unreadCount;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing bail bondsman dashboard data: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  void goToNotifications() {
    if (Get.isRegistered<BailBondsmanBottomNavBarController>()) {
      Get.find<BailBondsmanBottomNavBarController>().changeTabIndex(2);
    } else {
      Get.toNamed(AppRoutes.bailBondsmanNotification);
    }
  }

  void goToSchedule() {
    if (Get.isRegistered<BailBondsmanBottomNavBarController>()) {
      Get.find<BailBondsmanBottomNavBarController>().changeTabIndex(1);
    } else {
      Get.toNamed(AppRoutes.bailBondsmanSchedule);
    }
  }

  void goToActiveRequests() {
    Get.toNamed(AppRoutes.bailBondsmanActiveRequests);
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
