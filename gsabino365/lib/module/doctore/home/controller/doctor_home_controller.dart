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
import 'package:gsabino365/module/doctore/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';

class DoctorHomeController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();
  NotificationRepository? _notificationRepo;
  MeetingRepository? _meetingRepo;

  final RxString activeRole = 'Mental Health Professional'.obs;
  final RxString doctorName = 'Dr. Emily Chen, PsyD'.obs;
  final RxString doctorRole = 'Mental Health Professional'.obs;
  final RxString assignedNumber = 'CR-CHEN-01'.obs;
  final RxString doctorId = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxString languagesSpoken = 'English, Mandarin'.obs;
  final RxInt unreadNotifications = 0.obs;

  final RxInt liveCrisisCount = 0.obs;
  final RxList<MeetingModel> activeCrisisMeetings = <MeetingModel>[].obs;
  final RxList<Map<String, dynamic>> upcomingMeetingsList = <Map<String, dynamic>>[].obs;
  final RxInt upcomingScheduleCount = 0.obs;
  final RxBool isLoading = false.obs;

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _loadDoctorProfile();
    ever<UserModel?>(_authService.currentUser, (_) => _loadDoctorProfile());

    if (Get.isRegistered<ApiClient>()) {
      final client = Get.find<ApiClient>();
      _notificationRepo = NotificationRepository(apiClient: client);
      _meetingRepo = MeetingRepository(apiClient: client);
      refreshDashboardData();
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        refreshDashboardData(silent: true);
      });
    }
  }

  void _loadDoctorProfile() {
    final user = _authService.currentUser.value;
    if (user != null) {
      if (user.name != null && user.name!.isNotEmpty) {
        doctorName.value = user.name!;
      }
      doctorId.value = user.id ?? '';

      if (user.role != null && user.role!.isNotEmpty) {
        doctorRole.value = 'Mental Health Professional';
      }

      if (user.assignedNumber != null && user.assignedNumber!.isNotEmpty) {
        assignedNumber.value = user.assignedNumber!;
      } else if (user.badgeNumber != null && user.badgeNumber!.isNotEmpty) {
        assignedNumber.value = user.badgeNumber!;
      } else if (user.shortHexId != null && user.shortHexId!.isNotEmpty) {
        assignedNumber.value = user.shortHexId!.toUpperCase();
      } else if (user.id != null && user.id!.length >= 8) {
        assignedNumber.value = user.id!.substring(user.id!.length - 8).toUpperCase();
      }

      if (user.languagesSpoken != null && user.languagesSpoken!.isNotEmpty) {
        languagesSpoken.value = user.languagesSpoken!;
      }

      final img = user.image ?? user.profilePicture;
      if (img != null && img.isNotEmpty) {
        avatarUrl.value = ApiConstants.getFileUrl(img);
      }
    }
  }

  Future<void> refreshDashboardData({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      // 1. Fetch live active crisis meetings
      if (_meetingRepo != null) {
        final active = await _meetingRepo!.getActiveMeetings();
        final crisis = active.where((m) {
          final cat = (m.category ?? '').toUpperCase();
          final type = m.meetingType.toUpperCase();
          return cat == 'EMERGENCY' ||
              cat == 'CRISIS' ||
              cat == 'ENCOUNTER' ||
              type == 'EMERGENCY' ||
              type == 'INSTANT';
        }).toList();

        activeCrisisMeetings.assignAll(crisis.isNotEmpty ? crisis : active);
        liveCrisisCount.value = activeCrisisMeetings.length;
      }

      // 2. Fetch upcoming consultations
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
          }).map((e) => Map<String, dynamic>.from(e as Map)).toList();

          upcomingScheduleCount.value = upcoming.length;
          upcomingMeetingsList.assignAll(upcoming.take(3).toList());
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
      debugPrint('Error refreshing doctor dashboard data: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Direct 1-tap join of an active crisis session
  void joinActiveCrisis(MeetingModel meeting) {
    HapticFeedback.mediumImpact();
    Get.toNamed(
      AppRoutes.doctorLiveCall,
      arguments: meeting,
    );
  }

  /// Copy assigned license number
  void copyAssignedNumber() {
    Clipboard.setData(ClipboardData(text: assignedNumber.value));
    Get.rawSnackbar(
      message: 'Copied ID: #${assignedNumber.value}',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1550A6),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Open doctor's GoVia QR credential card
  void openDoctorQrCard({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: doctorName.value,
      userRole: 'Mental Health Professional',
      shortHexId: assignedNumber.value,
      fullId: doctorId.value,
      avatarUrl: avatarUrl.value.isNotEmpty ? avatarUrl.value : null,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrDialog({int initialTabIndex = 0}) => openDoctorQrCard(initialTabIndex: initialTabIndex);
  void openQrScanner() => openDoctorQrCard(initialTabIndex: 1);
  void copyHexId() => copyAssignedNumber();

  void openNotifications() {
    if (Get.isRegistered<DoctorBottomNavBarController>()) {
      Get.find<DoctorBottomNavBarController>().goToNotifications();
    } else {
      Get.toNamed(AppRoutes.doctorNotification);
    }
  }

  void openSchedule() {
    if (Get.isRegistered<DoctorBottomNavBarController>()) {
      Get.find<DoctorBottomNavBarController>().goToSchedule();
    } else {
      Get.toNamed(AppRoutes.doctorSchedule);
    }
  }

  void openActiveSessions() {
    Get.toNamed(AppRoutes.doctorActiveSessions);
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
