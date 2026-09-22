import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/models/user_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';
import 'package:gsabino365/module/police/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';

class PoliceHomeController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();
  NotificationRepository? _notificationRepo;
  MeetingRepository? _meetingRepo;

  final RxString activeRole = 'Police'.obs;
  final RxString officerName = 'Officer'.obs;
  final RxString officerTitle = 'Police Officer'.obs;
  final RxString badgeId = '2314-1548'.obs;
  final RxString officerId = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString department = 'Metropolitan Police Dept'.obs;
  final RxInt unreadNotifications = 0.obs;

  final RxInt liveIncidentsCount = 0.obs;
  final RxList<MeetingModel> activeIncidents = <MeetingModel>[].obs;
  final RxInt upcomingScheduleCount = 0.obs;
  final RxBool isLoading = false.obs;

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _loadOfficerProfile();
    ever<UserModel?>(_authService.currentUser, (_) => _loadOfficerProfile());

    if (Get.isRegistered<ApiClient>()) {
      final client = Get.find<ApiClient>();
      _notificationRepo = NotificationRepository(apiClient: client);
      _meetingRepo = MeetingRepository(apiClient: client);
      refreshDashboardData();
      _refreshTimer = Timer.periodic(const Duration(seconds: 7), (_) {
        refreshDashboardData(silent: true);
      });
    }
  }

  void _loadOfficerProfile() {
    final user = _authService.currentUser.value;
    if (user != null) {
      if (user.name != null && user.name!.isNotEmpty) {
        officerName.value = user.name!;
      }
      officerId.value = user.id ?? '';

      if (user.subRole != null && user.subRole!.isNotEmpty) {
        officerTitle.value = user.subRole!;
      }

      // Determine badge number
      if (user.badgeNumber != null && user.badgeNumber!.isNotEmpty) {
        badgeId.value = user.badgeNumber!;
      } else if (user.shortHexId != null && user.shortHexId!.isNotEmpty) {
        badgeId.value = user.shortHexId!.toUpperCase();
      } else if (user.id != null && user.id!.length >= 8) {
        badgeId.value = user.id!.substring(user.id!.length - 8).toUpperCase();
      }

      final img = user.image ?? user.profilePicture;
      if (img != null && img.isNotEmpty) {
        avatarUrl.value = ApiConstants.getFileUrl(img);
      }

      if (user.departmentOrPrecinct != null && user.departmentOrPrecinct!.isNotEmpty) {
        department.value = user.departmentOrPrecinct!;
      } else if (user.officeName != null && user.officeName!.isNotEmpty) {
        department.value = user.officeName!;
      }
    }
  }

  Future<void> refreshDashboardData({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      // 1. Fetch live active incident meetings
      if (_meetingRepo != null) {
        final active = await _meetingRepo!.getActiveMeetings();
        final encounters = active.where((m) {
          final cat = (m.category ?? '').toUpperCase();
          final type = m.meetingType.toUpperCase();
          return cat == 'ENCOUNTER' ||
              cat == 'EMERGENCY' ||
              type == 'EMERGENCY' ||
              type == 'INSTANT';
        }).toList();

        activeIncidents.assignAll(encounters.isNotEmpty ? encounters : active);
        liveIncidentsCount.value = activeIncidents.length;
      }

      // 2. Fetch upcoming duty schedule count
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
            if (type == 'EMERGENCY' || cat == 'EMERGENCY' || cat == 'ENCOUNTER') {
              return false;
            }
            return status == 'SCHEDULED' || status == 'ACTIVE';
          }).length;

          upcomingScheduleCount.value = upcoming;
        }
      }

      // 3. Fetch unread notifications count
      if (_notificationRepo != null) {
        final res = await _notificationRepo!.getNotifications(page: 1, limit: 10);
        if (res != null) {
          unreadNotifications.value = res.meta.unreadCount;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing police dashboard data: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Direct 1-tap join of an active citizen encounter or live SOS incident
  void joinActiveIncident(MeetingModel incident) {
    HapticFeedback.mediumImpact();
    Get.toNamed(
      AppRoutes.attorneyLiveCall,
      arguments: incident,
    );
  }

  /// Copy badge / short Hex ID
  void copyHexId() {
    Clipboard.setData(ClipboardData(text: badgeId.value));
    Get.rawSnackbar(
      message: 'Copied Officer ID: #${badgeId.value}',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1550A6),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Open real camera scanner to verify citizen QR code and join active incident
  void openScanner() {
    UserQrCardDialog.show(
      userName: officerName.value,
      userRole: 'Police Officer',
      shortHexId: badgeId.value,
      fullId: officerId.value,
      avatarUrl: avatarUrl.value.isNotEmpty ? avatarUrl.value : null,
      initialTabIndex: 1, // Open scanner directly
    );
  }

  /// Open officer's own GoVia QR credential card
  void openOfficerQrCard() {
    UserQrCardDialog.show(
      userName: officerName.value,
      userRole: 'Police Officer',
      shortHexId: badgeId.value,
      fullId: officerId.value,
      avatarUrl: avatarUrl.value.isNotEmpty ? avatarUrl.value : null,
      initialTabIndex: 0,
    );
  }

  void showStickerScanDialog() {
    openScanner();
  }

  void openQrDialog({int initialTabIndex = 0}) {
    if (initialTabIndex == 1) {
      openScanner();
    } else {
      openOfficerQrCard();
    }
  }

  void openQrScanner() => openScanner();

  void openNotifications() {
    if (Get.isRegistered<PoliceBottomNavBarController>()) {
      Get.find<PoliceBottomNavBarController>().goToNotifications();
    } else {
      Get.toNamed(AppRoutes.policeNotification);
    }
  }

  void openSchedule() {
    if (Get.isRegistered<PoliceBottomNavBarController>()) {
      Get.find<PoliceBottomNavBarController>().goToSchedule();
    } else {
      Get.toNamed(AppRoutes.policeSchedule);
    }
  }

  void openCrisisManagement() {
    Get.toNamed(AppRoutes.policeCrisisManagement);
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
