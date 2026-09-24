import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/core/widgets/govia_video_player_view.dart';
import 'package:gsabino365/data/models/meeting_model.dart';
import 'package:gsabino365/data/repositories/meeting_repository.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';

class CommonScheduleController extends GetxController {
  ApiClient get _apiClient => Get.find<ApiClient>();
  AuthService get _authService => Get.find<AuthService>();

  MeetingRepository get _meetingRepo {
    try {
      return Get.find<MeetingRepository>();
    } catch (_) {
      return MeetingRepository(apiClient: _apiClient);
    }
  }

  CitizenVaultController get _vaultController {
    try {
      return Get.find<CitizenVaultController>();
    } catch (_) {
      return Get.put(CitizenVaultController());
    }
  }

  final RxList<Map<String, dynamic>> meetings = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedTab = 'Upcoming'.obs; // 'Upcoming' | 'Past'

  Timer? _periodicRefreshTimer;

  String get currentUserId => _authService.currentUser.value?.id ?? '';

  String get userRole {
    final raw = _authService.currentUser.value?.role?.toUpperCase() ?? 'CITIZEN';
    return raw;
  }

  bool get isProfessional {
    return userRole == 'MENTAL_HEALTH_PROFESSIONAL' ||
        userRole == 'DOCTOR' ||
        userRole == 'ATTORNEY' ||
        userRole == 'POLICE' ||
        userRole == 'BAIL_BONDSMAN';
  }

  String get scheduleTitle {
    switch (userRole) {
      case 'MENTAL_HEALTH_PROFESSIONAL':
      case 'DOCTOR':
        return 'Clinical Consultations';
      case 'ATTORNEY':
        return 'Attorney Schedule';
      case 'POLICE':
        return 'Duty Schedule';
      case 'BAIL_BONDSMAN':
        return 'Bail Consultations';
      default:
        return 'Consultation Schedule';
    }
  }

  String get scheduleSubtitle {
    switch (userRole) {
      case 'MENTAL_HEALTH_PROFESSIONAL':
      case 'DOCTOR':
        return 'Patient telehealth consultations & clinical checkups';
      case 'ATTORNEY':
        return 'Client legal consultations & scheduled video hearings';
      case 'POLICE':
        return 'Department duty briefings & scheduled consultations';
      case 'BAIL_BONDSMAN':
        return 'Institutional verification & client bond consultations';
      default:
        return 'Your scheduled and instant video sessions';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchMyMeetings();

    // Auto refresh periodically to keep schedule status fresh
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchMyMeetings(silent: true);
    });
  }

  Future<void> fetchMyMeetings({bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;
      final response = await _apiClient.getData(ApiConstants.myMeetings);

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'];
        List items = [];
        if (rawData is List) {
          items = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          items = rawData['data'] as List;
        }

        meetings.assignAll(
          items.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching meetings in CommonScheduleController: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  bool _isConsultationScheduleMeeting(Map<String, dynamic> m) {
    final type = (m['meetingType'] ?? '').toString().toUpperCase();
    final cat = (m['category'] ?? '').toString().toUpperCase();
    final topic = (m['topic'] ?? '').toString().toLowerCase();

    // Exclude Emergency SOS and Govia Encounter sessions from Consultation Schedule
    if (type == 'EMERGENCY' || cat == 'EMERGENCY' || cat == 'ENCOUNTER') {
      return false;
    }

    // Exclude sessions created from "Start Govia" or "I'm being stopped / I feel unsafe"
    if (topic.contains('start govia') ||
        topic.contains('govia encounter') ||
        topic.contains('stopped') ||
        topic.contains('unsafe') ||
        topic.contains('emergency') ||
        topic.contains('sos') ||
        topic.contains('incident protocol') ||
        topic.contains('encounter')) {
      return false;
    }

    return true;
  }

  List<Map<String, dynamic>> get upcomingMeetings {
    return meetings.where((m) {
      if (!_isConsultationScheduleMeeting(m)) return false;
      final status = m['status']?.toString().toUpperCase() ?? 'SCHEDULED';
      return status == 'SCHEDULED' || status == 'ACTIVE';
    }).toList();
  }

  List<Map<String, dynamic>> get pastMeetings {
    return meetings.where((m) {
      if (!_isConsultationScheduleMeeting(m)) return false;
      final status = m['status']?.toString().toUpperCase() ?? '';
      return status == 'COMPLETED' || status == 'CANCELLED';
    }).toList();
  }

  // ─── JOIN MEETING (Role-Aware) ─────────────────────────────────────────────
  Future<void> joinMeeting(Map<String, dynamic> meeting) async {
    HapticFeedback.mediumImpact();

    final status = meeting['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final meetingType = meeting['meetingType']?.toString().toUpperCase() ?? 'SCHEDULED';
    final startTimeRaw = meeting['startTime'];
    final durationMinutes = int.tryParse(meeting['durationMinutes']?.toString() ?? '30') ?? 30;
    final topic = meeting['topic']?.toString() ?? 'Consultation Session';
    final meetingId = meeting['_id']?.toString() ?? meeting['id']?.toString() ?? '';

    if (status == 'COMPLETED') {
      showRecordingDialog(meeting);
      return;
    }

    if (meetingType == 'SCHEDULED' && startTimeRaw != null) {
      try {
        final startTime = DateTime.parse(startTimeRaw.toString()).toLocal();
        final now = DateTime.now();
        final windowStart = startTime.subtract(const Duration(minutes: 10));
        final windowEnd = startTime.add(Duration(minutes: durationMinutes));

        if (now.isBefore(windowStart)) {
          final diff = startTime.difference(now);
          final hours = diff.inHours;
          final minutes = diff.inMinutes % 60;
          final formattedStartTime = DateFormat('EEE, MMM d, yyyy • h:mm a').format(startTime);

          String timeRemainingStr = '';
          if (hours > 0) {
            timeRemainingStr = '$hours hr${hours > 1 ? 's' : ''} $minutes min${minutes > 1 ? 's' : ''}';
          } else {
            timeRemainingStr = '$minutes min${minutes > 1 ? 's' : ''}';
          }

          _showCountdownDialog(
            topic: topic,
            scheduledTimeStr: formattedStartTime,
            timeRemainingStr: timeRemainingStr,
          );
          return;
        }

        if (now.isAfter(windowEnd)) {
          Helpers.showWarning(
            'This scheduled meeting session has expired.',
          );
          return;
        }
      } catch (e) {
        debugPrint('Error parsing scheduled meeting time: $e');
      }
    }

    // Join meeting via repository if ID exists
    MeetingModel? meetingModel;
    try {
      if (meetingId.isNotEmpty) {
        meetingModel = await _meetingRepo.joinMeeting(meetingId);
      }
    } catch (_) {}

    meetingModel ??= MeetingModel(
      id: meetingId,
      roomName: meeting['roomName']?.toString() ?? 'room_$meetingId',
      topic: topic,
      status: 'ACTIVE',
      meetingType: meetingType,
      hostId: meeting['hostId']?.toString(),
      callerName: meeting['callerName']?.toString() ?? 'Client',
      callerAvatar: meeting['callerAvatar']?.toString(),
      createdAt: DateTime.now(),
    );

    // Route to live call screen depending on current user role
    if (userRole == 'MENTAL_HEALTH_PROFESSIONAL' || userRole == 'DOCTOR') {
      Get.toNamed(AppRoutes.doctorLiveCall, arguments: meetingModel);
    } else if (userRole == 'ATTORNEY' || userRole == 'POLICE' || userRole == 'BAIL_BONDSMAN') {
      Get.toNamed(AppRoutes.attorneyLiveCall, arguments: {'meeting': meeting});
    } else {
      Get.toNamed(AppRoutes.citizenLiveCall, arguments: {'meeting': meeting});
    }
  }

  void _showCountdownDialog({
    required String topic,
    required String scheduledTimeStr,
    required String timeRemainingStr,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.alarm_rounded,
                  color: const Color(0xFF1550A6),
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Meeting Not Started Yet',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                topic,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 15.sp, color: const Color(0xFF64748B)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            scheduledTimeStr,
                            style: GoogleFonts.inter(fontSize: 12.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.timelapse_rounded, size: 15.sp, color: const Color(0xFF1550A6)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Starts in: $timeRemainingStr',
                            style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1550A6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'You can join 10 minutes prior to the scheduled consultation time.',
                style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1550A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text('Got It', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── RESCHEDULE MEETING ───────────────────────────────────────────────────
  void showRescheduleDialog(Map<String, dynamic> meeting) {
    final meetingId = meeting['_id']?.toString() ?? meeting['id']?.toString() ?? '';
    final currentTopic = meeting['topic']?.toString() ?? 'Consultation Session';
    final duration = int.tryParse(meeting['durationMinutes']?.toString() ?? '30') ?? 30;

    DateTime initialDate = DateTime.now().add(const Duration(days: 1));
    if (meeting['startTime'] != null) {
      try {
        initialDate = DateTime.parse(meeting['startTime'].toString()).toLocal();
      } catch (_) {}
    }

    final Rx<DateTime> newDate = initialDate.obs;
    final Rx<TimeOfDay> newTime = TimeOfDay.fromDateTime(initialDate).obs;
    final topicCtrl = TextEditingController(text: currentTopic);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_calendar_rounded, color: const Color(0xFF1550A6), size: 20.sp),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Reschedule Meeting',
                    style: GoogleFonts.inter(fontSize: 17.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text('Topic / Reason', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              SizedBox(height: 6.h),
              TextField(
                controller: topicCtrl,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
              SizedBox(height: 14.h),
              Text('Select New Date & Time', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              SizedBox(height: 8.h),
              Obx(() => Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: Get.context!,
                          initialDate: newDate.value,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) newDate.value = picked;
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        DateFormat('MMM dd, yyyy').format(newDate.value),
                        style: GoogleFonts.inter(fontSize: 12.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: Get.context!,
                          initialTime: newTime.value,
                        );
                        if (picked != null) newTime.value = picked;
                      },
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text(
                        newTime.value.format(Get.context!),
                        style: GoogleFonts.inter(fontSize: 12.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                    ),
                  ),
                ],
              )),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final d = newDate.value;
                        final t = newTime.value;
                        final newStartDateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);

                        Get.back();
                        await rescheduleMeeting(
                          meetingId: meetingId,
                          newStartTime: newStartDateTime,
                          topic: topicCtrl.text.trim(),
                          durationMinutes: duration,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1550A6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                      ),
                      child: Text('Update', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> rescheduleMeeting({
    required String meetingId,
    required DateTime newStartTime,
    required String topic,
    required int durationMinutes,
  }) async {
    try {
      HapticFeedback.mediumImpact();
      final response = await _apiClient.patchData(
        ApiConstants.meetingDetails(meetingId),
        {
          'topic': topic,
          'startTime': newStartTime.toUtc().toIso8601String(),
          'durationMinutes': durationMinutes,
        },
      );

      if (response.statusCode == 200) {
        Helpers.showSuccess('Meeting rescheduled successfully', title: 'Rescheduled');
        fetchMyMeetings();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to reschedule meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to reschedule meeting');
    }
  }

  // ─── CANCEL MEETING ───────────────────────────────────────────────────────
  void confirmCancelMeeting(String meetingId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Cancel Meeting', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16.sp)),
        content: Text(
          'Are you sure you want to cancel this scheduled meeting session?',
          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Keep', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              cancelMeeting(meetingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> cancelMeeting(String meetingId) async {
    try {
      HapticFeedback.mediumImpact();
      final response = await _apiClient.patchData(ApiConstants.cancelMeeting(meetingId), {});
      if (response.statusCode == 200) {
        Helpers.showSuccess('Meeting cancelled');
        fetchMyMeetings();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to cancel meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to cancel meeting');
    }
  }

  // ─── DELETE MEETING ───────────────────────────────────────────────────────
  void confirmDeleteMeeting(String meetingId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Meeting Record', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16.sp)),
        content: Text(
          'Are you sure you want to completely remove this meeting record?',
          style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              deleteMeeting(meetingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteMeeting(String meetingId) async {
    try {
      HapticFeedback.mediumImpact();
      final response = await _apiClient.deleteData(ApiConstants.meetingDetails(meetingId));
      if (response.statusCode == 200) {
        Helpers.showSuccess('Meeting record deleted');
        fetchMyMeetings();
      } else {
        Helpers.showError(response.data?['message'] ?? 'Failed to delete meeting');
      }
    } catch (_) {
      Helpers.showError('Failed to delete meeting');
    }
  }

  // ─── RECORDING DIALOG ─────────────────────────────────────────────────────
  void showRecordingDialog(Map<String, dynamic> meeting) {
    final isLocked = meeting['isRecordingLocked'] == true;
    if (isLocked) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          child: Padding(
            padding: EdgeInsets.all(22.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: const Color(0xFF1550A6),
                    size: 32.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Cloud Recording Locked',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Cloud recording playback, video streaming, and evidence downloads are exclusive to Govia Premium citizens.',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1550A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.subscription);
                    },
                    child: Text(
                      'Upgrade to Premium',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final recordingUrl = meeting['recordingUrl']?.toString() ?? '';
    final topic = meeting['topic']?.toString() ?? 'Consultation Session';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: const Color(0xFF16A34A),
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Meeting Recording',
                style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Text(
                topic,
                style: GoogleFonts.inter(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              if (recordingUrl.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.videocam_rounded, color: const Color(0xFF1550A6), size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          recordingUrl,
                          style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1550A6)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      GoviaVideoPlayerView.open(
                        url: recordingUrl,
                        title: topic,
                        subtitle: 'Session Recording',
                      );
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                    label: Text('Watch Recording', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      Clipboard.setData(ClipboardData(text: recordingUrl));
                      Helpers.showSuccess('Recording link copied to clipboard!');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text('Copy Recording Link', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1550A6),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Recording processing in cloud. It will be available shortly.',
                  style: GoogleFonts.inter(fontSize: 12.5.sp, color: const Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: () {
                  Get.back();
                  showAddToVaultModal(meeting);
                },
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: Text('Save to Evidence Vault', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1550A6),
                  side: const BorderSide(color: Color(0xFF1550A6)),
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── VAULT INTEGRATION ────────────────────────────────────────────────────
  void showAddToVaultModal(Map<String, dynamic> meeting) async {
    final meetingId = meeting['_id']?.toString() ?? meeting['id']?.toString() ?? '';
    final topic = meeting['topic']?.toString() ?? 'Meeting Consultation Record';

    if (meetingId.isEmpty) {
      Helpers.showError('Invalid consultation record');
      return;
    }

    HapticFeedback.lightImpact();
    await _vaultController.fetchFolders(showLoader: false);

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.75),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_rounded, color: const Color(0xFF1550A6), size: 20.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to Evidence Vault',
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Securely attach this consultation recording to a vault folder',
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (Get.isBottomSheetOpen == true) Get.back();
                  _showCreateAndLinkFolderDialog(meeting);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Create New Vault Folder',
                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1550A6),
                  side: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            SizedBox(height: 8.h),
            Expanded(
              child: Obx(() {
                final folders = _vaultController.folders
                    .where((f) => !f.linkedMeetingIds.contains(meetingId))
                    .toList();
                if (folders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 48.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'No Vault Folders Found',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Tap above to create a folder and save this recording.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: folders.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return InkWell(
                      onTap: () async {
                        if (Get.isBottomSheetOpen == true) Get.back();
                        final ok = await _vaultController.linkMeetingToFolder(
                          folderId: folder.id,
                          meetingId: meetingId,
                          title: topic,
                        );
                        if (ok) {
                          meeting['vaultFolderId'] = {
                            '_id': folder.id,
                            'name': folder.name,
                            'category': folder.category,
                          };
                          meetings.refresh();
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.folder_rounded, color: const Color(0xFF1550A6), size: 18.sp),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (folder.description.isNotEmpty)
                                    Text(
                                      folder.description,
                                      style: GoogleFonts.inter(fontSize: 11.5.sp, color: const Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.add_circle_outline_rounded, color: const Color(0xFF1550A6), size: 22.sp),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCreateAndLinkFolderDialog(Map<String, dynamic> meeting) {
    final meetingId = meeting['_id']?.toString() ?? meeting['id']?.toString() ?? '';
    final defaultTitle = meeting['topic']?.toString() ?? 'Consultation Recording';
    final meetingCategory = meeting['category']?.toString().toUpperCase() ?? 'CONSULTATION';

    final nameCtrl = TextEditingController(text: defaultTitle);
    final descCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'New Vault Folder',
          style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a case folder to store your recordings and evidence.',
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Folder Title *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen == true) Get.back();
            },
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          Obx(() {
            final isSaving = _vaultController.isActionLoading.value;
            return ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = nameCtrl.text.trim();
                      if (title.isEmpty) {
                        Helpers.showWarning('Please enter a folder title');
                        return;
                      }
                      final folder = await _vaultController.createFolder(
                        name: title,
                        description: descCtrl.text.trim(),
                        category: meetingCategory,
                        showSuccessToast: false,
                      );
                      if (folder != null) {
                        if (Get.isDialogOpen == true) Get.back();
                        if (Get.isBottomSheetOpen == true) Get.back();
                        final ok = await _vaultController.linkMeetingToFolder(
                          folderId: folder.id,
                          meetingId: meetingId,
                          title: defaultTitle,
                        );
                        if (ok) {
                          meeting['vaultFolderId'] = {
                            '_id': folder.id,
                            'name': folder.name,
                            'category': folder.category,
                          };
                          meetings.refresh();
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1550A6),
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: isSaving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Create & Add', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            );
          }),
        ],
      ),
    );
  }
  @override
  void onClose() {
    _periodicRefreshTimer?.cancel();
    super.onClose();
  }
}
