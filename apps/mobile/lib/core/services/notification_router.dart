import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/notification_model.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';
import 'package:gsabino365/module/citizen/vault/model/vault_models.dart';

class NotificationRouter {
  /// Routes the user to the correct screen based on notification type, resource, and active user role
  static Future<void> navigate(NotificationModel notif) async {
    // 1. External link redirect if provided
    if (notif.link?.url != null && notif.link!.url.isNotEmpty) {
      final uri = Uri.tryParse(notif.link!.url);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final role = AuthService.to.currentUser.value?.role?.toUpperCase() ??
        AuthService.to.currentRole.value.toUpperCase();

    // 2. Incident / Emergency Encounter
    if (notif.isIncident) {
      _routeIncident(notif, role);
      return;
    }

    // 3. Session Recording
    if (notif.isRecording) {
      _routeRecording(notif, role);
      return;
    }

    // 4. Evidence Vault / Case Files
    if (notif.isVault) {
      _routeVault(notif, role);
      return;
    }

    // 5. Consultation / Meeting
    if (notif.isMeeting) {
      _routeMeeting(notif, role);
      return;
    }

    // 6. Role-specific duty / active requests / chat
    final typeLower = notif.type.toLowerCase();
    final resTypeLower = notif.resourceType.toLowerCase();

    if (typeLower == 'duty') {
      if (role == 'POLICE') {
        Get.toNamed(AppRoutes.policeSchedule);
        return;
      }
    }

    if (typeLower == 'bail' || resTypeLower == 'bond' || resTypeLower == 'indemnitor') {
      if (role == 'BAIL_BONDSMAN') {
        Get.toNamed(AppRoutes.bailBondsmanActiveRequests);
        return;
      }
    }

    if (typeLower == 'message' || resTypeLower == 'message') {
      if (role == 'ATTORNEY') {
        Get.toNamed(AppRoutes.attorneyChatList);
        return;
      }
    }

    if (typeLower == 'dispatch') {
      if (role == 'POLICE') {
        Get.toNamed(AppRoutes.policeBirdsEye);
        return;
      } else if (role == 'DOCTOR' || role == 'MENTAL_HEALTH_PROFESSIONAL') {
        Get.toNamed(AppRoutes.doctorDispatch);
        return;
      }
    }

    // 7. General fallback by role
    _routeFallback(role);
  }

  /// Handles incoming push notification payload
  static void navigateFromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notif = NotificationModel(
      id: data['id'] ?? data['_id'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      title: message.notification?.title ?? data['title'] ?? 'GoVia Alert',
      subtitle: message.notification?.body ?? data['body'] ?? data['subtitle'] ?? '',
      resourceType: data['resourceType'] ?? '',
      resourceId: data['resourceId'] ?? data['meetingId'] ?? data['folderId'] ?? '',
      metadata: data,
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    navigate(notif);
  }

  static void _routeIncident(NotificationModel notif, String role) {
    final status = notif.metadata?['status']?.toString().toUpperCase();
    final isLive = notif.metadata?['isLive'];
    if (isLive == false || status == 'COMPLETED' || status == 'CANCELLED' || notif.metadata?['endedAt'] != null) {
      Helpers.showWarning('This encounter has already ended.');
      _routeRecording(notif, role);
      return;
    }

    final meetingId = notif.resourceId.isNotEmpty
        ? notif.resourceId
        : (notif.metadata?['meetingId']?.toString() ?? '');

    final meetingArgs = {
      'meetingId': meetingId,
      'callerName': notif.callerName ?? 'Citizen',
      'location': notif.location ?? 'Active GPS Location',
      'topic': notif.topic ?? notif.title,
      'isHost': role == 'CITIZEN',
      'category': 'EMERGENCY',
      'status': status,
    };

    if (role == 'ATTORNEY' || role == 'POLICE' || role == 'BAIL_BONDSMAN') {
      Get.toNamed(AppRoutes.attorneyLiveCall, arguments: meetingArgs);
    } else if (role == 'DOCTOR' || role == 'MENTAL_HEALTH_PROFESSIONAL') {
      Get.toNamed(AppRoutes.doctorLiveCall, arguments: meetingArgs);
    } else {
      Get.toNamed(AppRoutes.citizenLiveCall, arguments: meetingArgs);
    }
  }

  static void _routeRecording(NotificationModel notif, String role) {
    if (role == 'ATTORNEY') {
      Get.toNamed(AppRoutes.attorneyEvidenceVault);
    } else {
      final vc = Get.isRegistered<CitizenVaultController>()
          ? Get.find<CitizenVaultController>()
          : Get.put(CitizenVaultController());
      vc.switchTab('Recordings');
      Get.toNamed(AppRoutes.citizenVault);
    }
  }

  static void _routeVault(NotificationModel notif, String role) {
    if (role == 'ATTORNEY') {
      Get.toNamed(AppRoutes.attorneyEvidenceVault);
      return;
    }

    final folderId = notif.metadata?['folderId']?.toString() ??
        (notif.resourceType == 'vault' && notif.resourceId.isNotEmpty ? notif.resourceId : null);

    if (folderId != null && folderId.isNotEmpty && !folderId.startsWith('vault_')) {
      if (!Get.isRegistered<CitizenVaultController>()) {
        Get.put(CitizenVaultController());
      }

      final folderModel = VaultFolderModel(
        id: folderId,
        name: notif.folderName ?? notif.title,
        description: notif.subtitle,
        category: notif.category ?? 'GENERAL',
        location: notif.location ?? '',
        incidentDate: notif.createdAt,
        createdAt: notif.createdAt,
        updatedAt: notif.updatedAt,
      );

      Get.toNamed(
        AppRoutes.citizenVaultFolderDetails,
        arguments: folderModel,
      );
    } else {
      Get.toNamed(AppRoutes.citizenVault);
    }
  }

  static void _routeMeeting(NotificationModel notif, String role) {
    if (notif.isLive) {
      _routeIncident(notif, role);
      return;
    }

    if (role == 'ATTORNEY') {
      Get.toNamed(AppRoutes.attorneySchedule);
    } else if (role == 'DOCTOR' || role == 'MENTAL_HEALTH_PROFESSIONAL') {
      Get.toNamed(AppRoutes.doctorSchedule);
    } else if (role == 'POLICE') {
      Get.toNamed(AppRoutes.policeSchedule);
    } else if (role == 'BAIL_BONDSMAN') {
      Get.toNamed(AppRoutes.bailBondsmanSchedule);
    } else {
      Get.toNamed(AppRoutes.citizenCommunity);
    }
  }

  static void _routeFallback(String role) {
    switch (role) {
      case 'ATTORNEY':
        Get.toNamed(AppRoutes.attorneyNotification);
        break;
      case 'DOCTOR':
      case 'MENTAL_HEALTH_PROFESSIONAL':
        Get.toNamed(AppRoutes.doctorNotification);
        break;
      case 'POLICE':
        Get.toNamed(AppRoutes.policeNotification);
        break;
      case 'BAIL_BONDSMAN':
        Get.toNamed(AppRoutes.bailBondsmanNotification);
        break;
      default:
        Get.toNamed(AppRoutes.citizenNotification);
        break;
    }
  }
}
