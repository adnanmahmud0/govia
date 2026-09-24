import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/services/location_service.dart';
import 'package:gsabino365/core/services/voice_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/data/repositories/notification_repository.dart';

class CitizenHomeController extends GetxController with WidgetsBindingObserver {
  final AuthService _authService = Get.find<AuthService>();

  final RxString activeRole = 'Citizen'.obs;

  // Reactive Connection & Hardware Status (accurate to real device permissions)
  final RxBool isGpsActive = false.obs;
  final RxBool isVoiceActive = false.obs;
  final RxBool isCameraActive = false.obs;

  // Profile Getters bound to real AuthService session
  String get userName {
    final name = _authService.currentUser.value?.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Citizen';
  }

  String get userRole {
    final raw = _authService.currentUser.value?.role ?? _authService.currentRole.value;
    if (raw.isEmpty) return 'Citizen';
    switch (raw.toUpperCase()) {
      case 'CITIZEN':
        return 'Citizen';
      case 'ATTORNEY':
        return 'Attorney';
      case 'POLICE':
        return 'Police Officer';
      case 'DOCTOR':
        return 'Doctor';
      case 'BAIL_BONDSMAN':
        return 'Bail Bondsman';
      case 'ADMIN':
      case 'SUPER_ADMIN':
        return 'Admin';
      default:
        return raw.capitalizeFirst ?? raw;
    }
  }

  String get userId {
    final user = _authService.currentUser.value;
    final id = user?.id?.trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final assigned = user?.assignedNumber?.trim();
    if (assigned != null &&
        assigned.isNotEmpty &&
        assigned != user?.phoneNumber &&
        assigned != user?.phone) {
      return assigned;
    }
    final badge = user?.badgeNumber?.trim();
    if (badge != null && badge.isNotEmpty) {
      return badge;
    }
    return 'N/A';
  }

  String get assignedNumber => userId;

  String get shortHexId {
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
    return '00000000';
  }

  String get fullId {
    return _authService.currentUser.value?.id?.trim() ?? 'N/A';
  }

  void openQrDialog({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: userName,
      userRole: userRole,
      shortHexId: shortHexId,
      fullId: fullId,
      avatarUrl: avatarUrl,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrScanner() => openQrDialog(initialTabIndex: 1);

  String? get avatarUrl {
    final img = _authService.currentUser.value?.image?.trim() ??
        _authService.currentUser.value?.profilePicture?.trim();
    if (img != null && img.isNotEmpty) {
      return ApiConstants.getFileUrl(img);
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _refreshProfile();
    _checkHardwarePermissions();
  }

  @override
  void onClose() {
    VoiceService().stopListening();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkHardwarePermissions();
    }
  }

  final RxInt unreadNotificationCount = 0.obs;

  Future<void> _refreshProfile() async {
    try {
      await _authService.fetchProfile();
      await _fetchNotificationCount();
    } catch (_) {}
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final repo = NotificationRepository(apiClient: Get.find<ApiClient>());
      final res = await repo.getNotifications(limit: 5);
      if (res != null) {
        unreadNotificationCount.value = res.meta.unreadCount;
      }
    } catch (_) {}
  }

  Future<void> _checkHardwarePermissions() async {
    try {
      final locStatus = await Permission.locationWhenInUse.status;
      isGpsActive.value = locStatus.isGranted || locStatus.isLimited;

      final micStatus = await Permission.microphone.status;
      isVoiceActive.value = micStatus.isGranted;

      final camStatus = await Permission.camera.status;
      isCameraActive.value = camStatus.isGranted;
    } catch (_) {
      // Keep existing states if platform check fails
    }
  }

  // ──────────────────────── EMERGENCY SESSION DISPATCH ────────────────────────

  Future<void> startEmergencySession({String? reason}) async {
    HapticFeedback.heavyImpact();

    final user = _authService.currentUser.value;
    final attorney = user?.preferredAttorney?.trim();
    final bail = user?.preferredBailBondsman?.trim();

    // Fast-path: query device GPS location for live location sharing
    Position? position;
    try {
      position = await LocationService.getCurrentLocation(
        timeout: const Duration(seconds: 3),
      );
      if (position != null) {
        isGpsActive.value = true;
      }
    } catch (e) {
      debugPrint('[CitizenHome] Location acquisition error: $e');
    }

    final double? lat = position?.latitude;
    final double? lng = position?.longitude;
    final String? locAddress = (lat != null && lng != null)
        ? LocationService.formatCoordinates(lat, lng)
        : null;

    MeetingModel? meeting;
    try {
      final apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : Get.put(ApiClient());
      final meetingRepo = MeetingRepository(apiClient: apiClient);
      meeting = await meetingRepo.startEmergencyCall(
        topic: reason ?? 'Emergency Incident Protocol',
        preferredAttorney: attorney,
        preferredBailBondsman: bail,
        latitude: lat,
        longitude: lng,
        locationAddress: locAddress,
      );
    } catch (e) {
      debugPrint('Error initiating emergency session: $e');
    }

    // Navigate immediately to meeting room as host with the created meeting payload
    Get.toNamed(
      AppRoutes.citizenLiveCall,
      arguments: meeting != null
          ? {
              'meeting': meeting,
              'meetingId': meeting.id,
              'roomName': meeting.roomName,
              'token': meeting.token,
              'livekitUrl': meeting.livekitUrl,
              'topic': meeting.topic,
              'isHost': true,
              'autoRecord': true,
              'emergency': true,
              'latitude': lat,
              'longitude': lng,
              'locationAddress': locAddress,
            }
          : {
              'isHost': true,
              'autoRecord': true,
              'emergency': true,
              'latitude': lat,
              'longitude': lng,
              'locationAddress': locAddress,
            },
    );
  }

  // ──────────────────────── STATUS TOGGLE HANDLERS ────────────────────────

  Future<void> toggleGps() async {
    HapticFeedback.lightImpact();
    if (!isGpsActive.value) {
      try {
        final status = await Permission.locationWhenInUse.request();
        if (status.isPermanentlyDenied) {
          _showPermissionSettingsPrompt('GPS / Location');
          return;
        }
        if (status.isGranted || status.isLimited) {
          isGpsActive.value = true;
          _showStatusFeedback(
            'GPS Activated',
            'Location tracking is active and syncing',
            Icons.location_on_rounded,
            true,
          );
          return;
        }
      } catch (_) {}
      isGpsActive.value = false;
      _showStatusFeedback(
        'GPS Deactivated',
        'Location permission was not granted',
        Icons.location_off_rounded,
        false,
      );
    } else {
      isGpsActive.value = false;
      _showStatusFeedback(
        'GPS Deactivated',
        'Location tracking is paused',
        Icons.location_off_rounded,
        false,
      );
    }
  }

  Future<void> toggleVoice() async {
    HapticFeedback.lightImpact();
    if (!isVoiceActive.value) {
      try {
        final status = await Permission.microphone.request();
        if (status.isPermanentlyDenied) {
          _showPermissionSettingsPrompt('Microphone');
          return;
        }
        if (status.isGranted) {
          isVoiceActive.value = true;
          VoiceService().startListening(
            onWakeWord: () {
              _showStatusFeedback(
                'Voice Trigger Detected!',
                'Saying "Start Govia" activated emergency response',
                Icons.mic_rounded,
                true,
              );
              startEmergencySession(reason: 'Voice Wake Word: Start Govia');
            },
          );
          _showStatusFeedback(
            'Voice Monitoring Activated',
            'Listening for wake word: "Start Govia"',
            Icons.mic_rounded,
            true,
          );
          return;
        }
      } catch (_) {}
      isVoiceActive.value = false;
      _showStatusFeedback(
        'Voice Deactivated',
        'Microphone permission was not granted',
        Icons.mic_off_rounded,
        false,
      );
    } else {
      isVoiceActive.value = false;
      VoiceService().stopListening();
      _showStatusFeedback(
        'Voice Deactivated',
        'Microphone monitoring is muted',
        Icons.mic_off_rounded,
        false,
      );
    }
  }

  Future<void> toggleCamera() async {
    HapticFeedback.lightImpact();
    if (!isCameraActive.value) {
      try {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          _showPermissionSettingsPrompt('Camera');
          return;
        }
        if (status.isGranted) {
          isCameraActive.value = true;
          _showStatusFeedback(
            'Camera Activated',
            'Live camera stream is ready for emergency protocols',
            Icons.videocam_rounded,
            true,
          );
          return;
        }
      } catch (_) {}
      isCameraActive.value = false;
      _showStatusFeedback(
        'Camera Deactivated',
        'Camera permission was not granted',
        Icons.videocam_off_rounded,
        false,
      );
    } else {
      isCameraActive.value = false;
      _showStatusFeedback(
        'Camera Deactivated',
        'Camera feed is disabled',
        Icons.videocam_off_rounded,
        false,
      );
    }
  }

  void _showStatusFeedback(
    String title,
    String message,
    IconData icon,
    bool isActive,
  ) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.rawSnackbar(
      titleText: Row(
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
      messageText: Text(
        message,
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
        ),
      ),
      backgroundColor: const Color(0xFF0F172A),
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showPermissionSettingsPrompt(String feature) {
    Get.defaultDialog(
      title: '$feature Permission Required',
      titleStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
      middleText:
          'Please allow $feature permission in device settings to enable this feature.',
      middleTextStyle: GoogleFonts.inter(fontSize: 13),
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF1550A6),
      textConfirm: 'Open Settings',
      textCancel: 'Cancel',
      onConfirm: () {
        Get.back();
        openAppSettings();
      },
    );
  }
}
