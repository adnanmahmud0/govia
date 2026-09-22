import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';
import 'package:gsabino365/module/attorney/notification/controller/attorney_notification_controller.dart';
import 'package:gsabino365/module/attorney/profile/controller/attorney_profile_controller.dart';

class AttorneyHomeController extends GetxController {
  final RxString activeRole = 'Attorney'.obs;
  
  late AttorneyProfileController profileController;
  MeetingRepository? _meetingRepo;
  Timer? _refreshTimer;

  final RxString assignedNumber = 'OH-882910'.obs;
  final RxInt liveIncidentsCount = 0.obs;
  final RxInt upcomingSupportCount = 0.obs;
  final RxInt evidenceVaultCount = 0.obs;
  final RxInt unreadNotificationsCount = 0.obs;

  String get userName {
    if (Get.isRegistered<AuthService>()) {
      final name = Get.find<AuthService>().currentUser.value?.name?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return profileController.name.value;
  }

  String get avatarUrl {
    if (Get.isRegistered<AuthService>()) {
      final user = Get.find<AuthService>().currentUser.value;
      final img = user?.image ?? user?.profilePicture;
      if (img != null && img.isNotEmpty) return img;
    }
    return profileController.avatarUrl.value;
  }

  String get userRole => 'Attorney';

  String get userId {
    if (Get.isRegistered<AuthService>()) {
      final user = Get.find<AuthService>().currentUser.value;
      final id = user?.id?.trim();
      if (id != null && id.isNotEmpty) return id;
      final bar = user?.barAssociationNumber?.trim();
      if (bar != null && bar.isNotEmpty) return bar;
    }
    return assignedNumber.value;
  }

  String get shortHexId {
    if (Get.isRegistered<AuthService>()) {
      final user = Get.find<AuthService>().currentUser.value;
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
    return '882910AA';
  }

  String get fullId {
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>().currentUser.value?.id?.trim() ?? userId;
    }
    return userId;
  }

  void openQrDialog({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: userName,
      userRole: userRole,
      shortHexId: shortHexId,
      fullId: fullId,
      avatarUrl: avatarUrl.isNotEmpty ? ApiConstants.getFileUrl(avatarUrl) : null,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrScanner() => openQrDialog(initialTabIndex: 1);

  void copyHexId() {
    Clipboard.setData(ClipboardData(text: shortHexId));
    Get.rawSnackbar(
      message: 'Copied Short Hex ID: #$shortHexId',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1E3A8A),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onInit() {
    super.onInit();
    profileController = Get.find<AttorneyProfileController>();
    if (Get.isRegistered<ApiClient>()) {
      _meetingRepo = MeetingRepository(apiClient: Get.find<ApiClient>());
      refreshActiveCount();
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        refreshActiveCount();
      });
    }
  }

  Future<void> refreshActiveCount() async {
    try {
      if (_meetingRepo != null) {
        final meetings = await _meetingRepo!.getActiveMeetings();
        liveIncidentsCount.value = meetings.length;
      }
      if (Get.isRegistered<ApiClient>()) {
        final client = Get.find<ApiClient>();
        final response = await client.getData('/vault/folders');
        if (response.statusCode == 200 && response.data != null) {
          final list = response.data['data'];
          if (list is List) {
            evidenceVaultCount.value = list.length;
          }
        }

        // Fetch upcoming meetings count
        final meetingRes = await client.getData(ApiConstants.myMeetings);
        if (meetingRes.statusCode == 200 && meetingRes.data != null) {
          final rawData = meetingRes.data['data'];
          List items = [];
          if (rawData is List) {
            items = rawData;
          } else if (rawData is Map && rawData['data'] is List) {
            items = rawData['data'] as List;
          }
          final count = items.where((e) {
            if (e is! Map) return false;
            final status = e['status']?.toString().toUpperCase() ?? 'ACTIVE';
            return status == 'SCHEDULED' || status == 'ACTIVE';
          }).length;
          upcomingSupportCount.value = count;
        }
      }

      // Sync unread notification count
      if (Get.isRegistered<AttorneyNotificationController>()) {
        unreadNotificationsCount.value = Get.find<AttorneyNotificationController>().unreadCount;
      } else if (Get.isRegistered<ApiClient>()) {
        final repo = NotificationRepository(apiClient: Get.find<ApiClient>());
        final res = await repo.getNotifications(limit: 5);
        if (res != null) {
          unreadNotificationsCount.value = res.meta.unreadCount;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing active counts: $e');
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
