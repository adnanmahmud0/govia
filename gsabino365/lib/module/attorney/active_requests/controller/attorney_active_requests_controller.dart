import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/location_service.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/module/attorney/profile/controller/attorney_profile_controller.dart';

class AttorneyActiveRequestsController extends GetxController {
  late final MeetingRepository meetingRepo;

  final RxList<Map<String, dynamic>> activeRequests = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isJoining = false.obs;
  final RxString joiningMeetingId = ''.obs;

  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    meetingRepo = Get.find<MeetingRepository>();
    loadActiveRequests();
    // Poll every 4 seconds for new incoming citizen calls
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      loadActiveRequests(silent: true);
    });
  }

  Future<void> loadActiveRequests({bool silent = false}) async {
    if (!silent) isLoading.value = true;

    try {
      final meetings = await meetingRepo.getActiveMeetings();
      final seenIds = <String>{};
      final uniqueMeetings = <MeetingModel>[];
      for (final m in meetings) {
        if (m.id.isNotEmpty && !seenIds.contains(m.id)) {
          seenIds.add(m.id);
          uniqueMeetings.add(m);
        }
      }

      final mapped = uniqueMeetings.map((m) {
        final uId = m.userId ?? '';
        final shortId = uId.length >= 6
            ? uId.substring(uId.length - 6).toUpperCase()
            : (uId.isNotEmpty ? uId.toUpperCase() : 'N/A');
        final avatarUrl = (m.callerAvatar != null && m.callerAvatar!.isNotEmpty)
            ? ApiConstants.getFileUrl(m.callerAvatar)
            : '';
        final hasCoords = m.latitude != null && m.longitude != null;
        final locText = m.locationAddress != null && m.locationAddress!.isNotEmpty
            ? m.locationAddress!
            : hasCoords
                ? LocationService.formatCoordinates(m.latitude!, m.longitude!)
                : (m.topic.isNotEmpty ? m.topic : 'Emergency Incident');
        return {
          'id': m.id,
          'meeting': m,
          'name': m.callerName ?? 'Citizen Caller',
          'shortId': shortId,
          'location': locText,
          'latitude': m.latitude,
          'longitude': m.longitude,
          'hasLiveLocation': hasCoords || (m.locationAddress != null && m.locationAddress!.isNotEmpty),
          'state': 'OH',
          'waitingTime': _formatWaitTime(m.createdAt),
          'code': m.roomName,
          'avatar': avatarUrl,
          'isReal': true,
        };
      }).toList();

      activeRequests.assignAll(mapped);
    } catch (e) {
      debugPrint('Error loading active requests: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  String _formatWaitTime(DateTime? created) {
    if (created == null) return 'Live now';
    final diff = DateTime.now().difference(created);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  void copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'Copied',
      'Verification code copied to clipboard!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> joinRequest(Map<String, dynamic> request) async {
    // Jurisdiction license check
    if (Get.isRegistered<AttorneyProfileController>()) {
      final profileController = Get.find<AttorneyProfileController>();
      final allowedStates = profileController.licensedStates.value;
      final requestState = (request['state'] as String?) ?? 'OH';

      bool isAllowed = false;
      if (allowedStates.isEmpty || allowedStates.toLowerCase().contains('nationwide')) {
        isAllowed = true;
      } else {
        final statesList =
            allowedStates.split(',').map((s) => s.trim().toLowerCase());
        if (statesList.contains(requestState.toLowerCase())) {
          isAllowed = true;
        }
      }

      if (!isAllowed) {
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Jurisdiction Alert'),
              ],
            ),
            content: Text(
                'This call originates from $requestState.\n\nYour profile license ($allowedStates) does not cover this state.\n\nOnly attorneys licensed to practice in $requestState can accept this call.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close',
                    style: TextStyle(color: Color(0xFF1550A6))),
              ),
            ],
          ),
        );
        return;
      }
    }

    final meeting = request['meeting'];
    final meetingId = request['id']?.toString() ?? (meeting is MeetingModel ? meeting.id : '');

    if (meeting is MeetingModel) {
      isJoining.value = true;
      joiningMeetingId.value = meeting.id;

      try {
        final joined = await meetingRepo.joinMeeting(meeting.id);
        isJoining.value = false;
        joiningMeetingId.value = '';

        // Merge meeting metadata so the live call view has complete citizen name, avatar, start time, and fresh token
        final effectiveMeeting = MeetingModel(
          id: meeting.id,
          roomName: (joined != null && joined.roomName.isNotEmpty)
              ? joined.roomName
              : meeting.roomName,
          topic: meeting.topic,
          status: meeting.status,
          meetingType: meeting.meetingType,
          token: joined?.token ?? meeting.token,
          livekitUrl: joined?.livekitUrl ?? meeting.livekitUrl,
          sessionName: joined?.sessionName ?? meeting.sessionName,
          callerName: meeting.callerName ?? joined?.callerName,
          callerPhone: meeting.callerPhone ?? joined?.callerPhone,
          callerAvatar: meeting.callerAvatar ?? joined?.callerAvatar,
          userId: meeting.userId ?? joined?.userId,
          hostId: meeting.hostId ?? joined?.hostId,
          createdAt: meeting.createdAt ?? joined?.createdAt,
        );

        Get.toNamed(
          AppRoutes.attorneyLiveCall,
          arguments: effectiveMeeting,
        );
      } catch (e) {
        isJoining.value = false;
        joiningMeetingId.value = '';
        Get.toNamed(
          AppRoutes.attorneyLiveCall,
          arguments: meeting,
        );
      }
    } else if (meetingId.isNotEmpty) {
      isJoining.value = true;
      joiningMeetingId.value = meetingId;
      try {
        final joined = await meetingRepo.joinMeeting(meetingId);
        isJoining.value = false;
        joiningMeetingId.value = '';
        Get.toNamed(
          AppRoutes.attorneyLiveCall,
          arguments: joined ?? request,
        );
      } catch (_) {
        isJoining.value = false;
        joiningMeetingId.value = '';
        Get.toNamed(AppRoutes.attorneyLiveCall, arguments: request);
      }
    } else {
      Get.toNamed(AppRoutes.attorneyLiveCall);
    }
  }

  void openGoogleMaps(Map<String, dynamic> item) {
    final lat = item['latitude'] is num ? (item['latitude'] as num).toDouble() : null;
    final lng = item['longitude'] is num ? (item['longitude'] as num).toDouble() : null;
    if (lat != null && lng != null) {
      LocationService.openGoogleMaps(latitude: lat, longitude: lng);
    } else {
      final loc = item['location']?.toString() ?? '';
      if (loc.isNotEmpty) {
        LocationService.openGoogleMapsByQuery(loc);
      }
    }
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }
}
