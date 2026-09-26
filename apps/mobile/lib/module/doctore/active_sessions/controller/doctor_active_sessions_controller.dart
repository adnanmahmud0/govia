import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';

class DoctorActiveSessionsController extends GetxController {
  late final MeetingRepository _meetingRepo;

  final RxList<MeetingModel> activeMeetings = <MeetingModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final client = Get.find<ApiClient>();
    _meetingRepo = MeetingRepository(apiClient: client);
    fetchActiveSessions();
  }

  Future<void> fetchActiveSessions() async {
    try {
      isLoading.value = true;
      final list = await _meetingRepo.getActiveMeetings();
      activeMeetings.assignAll(list);
    } catch (_) {
      // Fallback
    } finally {
      isLoading.value = false;
    }
  }

  void openMeeting(MeetingModel meeting) {
    HapticFeedback.mediumImpact();
    if (meeting.status == 'COMPLETED' || meeting.status == 'CANCELLED' || meeting.endedAt != null) {
      Helpers.showWarning('This session has already ended.');
      activeMeetings.removeWhere((m) => m.id == meeting.id);
      return;
    }
    Get.toNamed(
      AppRoutes.doctorLiveCall,
      arguments: meeting,
    );
  }

  void openMockSession(Map<String, dynamic> session) {
    HapticFeedback.mediumImpact();
    final mockModel = MeetingModel(
      id: session['id'] ?? 'mock_1',
      roomName: 'doctor_crisis_${session['id']}',
      topic: session['title'] ?? 'Emergency Medical Support',
      status: 'ACTIVE',
      meetingType: 'EMERGENCY',
      callerName: session['officer'] ?? 'First Responder',
      createdAt: DateTime.now(),
    );

    Get.toNamed(
      AppRoutes.doctorLiveCall,
      arguments: mockModel,
    );
  }

  // Default fallback items for testing / preview when no live emergency is ongoing
  final List<Map<String, dynamic>> defaultMockSessions = [
    {
      'id': '1',
      'title': 'Priority 1: Emergency Mental Health Support',
      'officer': 'Officer: Johnson (Badge #4829)',
      'district': 'District 4 • Responder unit on-site',
      'time': '2m ago',
      'avatar': 'assets/images/driver_avatar.png',
    },
    {
      'id': '2',
      'title': 'Priority 2: De-escalation Consultation',
      'officer': 'Officer: Martinez (Precinct 7)',
      'district': 'District 2 • Traffic stop intervention',
      'time': '5m ago',
      'avatar': 'assets/images/user_avatar.png',
    },
    {
      'id': '3',
      'title': 'Priority 1: Acute Distress Evaluation',
      'officer': 'Paramedic Unit 12',
      'district': 'Metro Station • Field triage',
      'time': '12m ago',
      'avatar': 'assets/images/businessman_avatar.png',
    },
  ];
}
