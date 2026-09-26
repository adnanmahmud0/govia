import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/location_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';

class BailBondsmanActiveRequestsController extends GetxController {
  final RxList<Map<String, dynamic>> requests = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  MeetingRepository? _meetingRepo;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<ApiClient>()) {
      _meetingRepo = MeetingRepository(apiClient: Get.find<ApiClient>());
      loadActiveRequests();
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        loadActiveRequests(silent: true);
      });
    }
  }

  Future<void> loadActiveRequests({bool silent = false}) async {
    if (_meetingRepo == null) return;
    if (!silent) isLoading.value = true;
    try {
      final meetings = await _meetingRepo!.getActiveMeetings();
      final mapped = meetings.map((m) {
        String avatarUrl = '';
        if (m.callerAvatar != null && m.callerAvatar!.isNotEmpty) {
          avatarUrl = ApiConstants.getFileUrl(m.callerAvatar);
        }

        final hasCoords = m.latitude != null && m.longitude != null;
        final locText = m.locationAddress != null && m.locationAddress!.isNotEmpty
            ? m.locationAddress!
            : hasCoords
                ? LocationService.formatCoordinates(m.latitude!, m.longitude!)
                : (m.topic.isNotEmpty ? m.topic : 'Bail Assistance Required');

        return {
          'id': m.id,
          'meeting': m,
          'name': m.callerName ?? 'Citizen Caller',
          'location': locText,
          'latitude': m.latitude,
          'longitude': m.longitude,
          'hasLiveLocation': hasCoords || (m.locationAddress != null && m.locationAddress!.isNotEmpty),
          'waitingTime': 'Live now',
          'code': m.roomName.isNotEmpty ? m.roomName : 'ROOM-${m.id.substring(0, m.id.length > 6 ? 6 : m.id.length).toUpperCase()}',
          'avatar': avatarUrl,
        };
      }).toList();
      requests.assignAll(mapped);
    } catch (e) {
      debugPrint('Error loading bail active requests: $e');
    } finally {
      if (!silent) isLoading.value = false;
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

  Future<void> joinMeeting(Map<String, dynamic> item) async {
    HapticFeedback.mediumImpact();

    final meetingId = item['id']?.toString() ?? '';
    final meetingObj = item['meeting'];

    if (meetingId.isEmpty) {
      Helpers.showWarning('Invalid encounter ID.');
      return;
    }

    MeetingModel? meetingModel;
    if (meetingObj is MeetingModel) {
      if (meetingObj.status == 'COMPLETED' || meetingObj.status == 'CANCELLED' || meetingObj.endedAt != null) {
        Helpers.showWarning('This encounter has already ended.');
        requests.removeWhere((r) => r['id'] == meetingId);
        return;
      }
      meetingModel = meetingObj;
    }

    try {
      if (_meetingRepo != null) {
        final joined = await _meetingRepo!.joinMeeting(meetingId);
        if (joined == null) {
          final msg = _meetingRepo!.lastErrorMessage ?? 'This encounter has already ended.';
          Helpers.showWarning(msg);
          requests.removeWhere((r) => r['id'] == meetingId);
          return;
        }
        meetingModel = joined;
      }
    } catch (e) {
      debugPrint('Note: Join participant registration returned: $e');
      Helpers.showWarning('This encounter has ended or is unavailable.');
      requests.removeWhere((r) => r['id'] == meetingId);
      return;
    }

    if (meetingModel == null) {
      Helpers.showWarning('This encounter is unavailable.');
      requests.removeWhere((r) => r['id'] == meetingId);
      return;
    }

    Get.toNamed(
      AppRoutes.attorneyLiveCall,
      arguments: meetingModel,
    );
  }

  void initiateHandoffCall() {
    HapticFeedback.lightImpact();
    if (requests.isEmpty) {
      Helpers.showCustomSnackBar(
        'No active citizen verification requests are waiting for handoff right now.',
        type: SnackBarType.info,
      );
      return;
    }

    if (requests.length == 1) {
      joinMeeting(requests.first);
      return;
    }

    // If multiple active requests, show modal selector
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Handoff Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            ...requests.map((r) => ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.person, color: Color(0xFF1550A6)),
                  ),
                  title: Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(r['location'] as String),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Get.back();
                    joinMeeting(r);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.rawSnackbar(
      message: 'Room Code #$text copied to clipboard',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1550A6),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }
}
