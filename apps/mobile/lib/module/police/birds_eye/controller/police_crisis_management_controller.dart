import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/data/models/meeting_model.dart';

class PoliceCrisisManagementController extends GetxController {
  final AuthService _authService = AuthService.to;

  final RxString activeIncidentName = 'Sarah Johnson'.obs;
  final RxString status = 'Active Encrypted Live Feed'.obs;
  final RxString gpsLocation = '40.7128° N, 74.0060° W'.obs;
  final RxString supervisorName = 'Officer On-Duty'.obs;
  final RxBool isEscalated = false.obs;
  final RxBool isAudioMuted = false.obs;

  final RxList<String> logs = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    final user = _authService.currentUser.value;
    if (user != null && user.name != null && user.name!.isNotEmpty) {
      supervisorName.value = user.name!;
    }

    final dynamic args = Get.arguments;
    if (args is MeetingModel) {
      activeIncidentName.value = args.callerName ?? args.topic;
      status.value = 'Active Live Incident • ${args.roomName}';
    } else if (args is Map) {
      if (args['name'] != null) activeIncidentName.value = args['name'].toString();
      if (args['topic'] != null) activeIncidentName.value = args['topic'].toString();
    }

    logs.assignAll([
      'Scanning secured QR code from citizen encounter...',
      'Secured credentials validated successfully.',
      'Establishing encrypted stream tunnel to Command Center...',
      'Stream connection verified. GPS location lock active.',
      'Officer ${supervisorName.value} joined the crisis monitoring session.',
      'GoVia Command Center has fully authorized live oversight.',
    ]);
  }

  void toggleEscalate() {
    isEscalated.toggle();
    if (isEscalated.value) {
      logs.add('[PRIORITY ESCALATED] Crisis supervisor & legal de-escalation requested.');
      Get.snackbar(
        'Priority Escalated',
        'Command Center alerted for priority crisis assistance.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
    } else {
      logs.add('[NORMAL] Incident priority returned to standard monitoring.');
    }
  }

  void toggleAudio() {
    isAudioMuted.toggle();
    logs.add(isAudioMuted.value ? 'Officer microphone muted.' : 'Officer microphone live.');
  }

  void disconnectStream() {
    Get.back();
    Get.snackbar(
      'Session Closed',
      'Crisis Management live stream closed cleanly.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
    );
  }
}
