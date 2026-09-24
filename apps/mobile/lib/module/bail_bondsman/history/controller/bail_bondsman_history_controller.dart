import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/core/widgets/govia_video_player_view.dart';

class BailBondsmanHistoryController extends GetxController {
  ApiClient get _apiClient => Get.find<ApiClient>();

  final RxBool isPlaying = false.obs;
  final RxDouble currentPosition = 380.0.obs;
  final RxBool isMuted = false.obs;
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = false.obs;

  final RxList<Map<String, dynamic>> recordings = <Map<String, dynamic>>[].obs;

  static final List<Map<String, dynamic>> _defaultRecordings = [
    {
      'title': 'Marcus Thorne - Bail Assessment',
      'date': 'June 11, 2026',
      'time': '2:15 PM',
      'duration': '10:15',
      'durationSeconds': 615.0,
      'recTime': '14:15:10',
      'size': '9.8 MB',
      'recordingUrl': 'https://storage.googleapis.com/govia-vault/recordings/bail_assessment_thorne.mp4',
      'notes': 'Conducted pre-trial bail assessment and collateral verification. Client approved for emergency bond release.',
    },
    {
      'title': 'Julian Rossi - Bond Signing',
      'date': 'June 09, 2026',
      'time': '4:30 PM',
      'duration': '15:20',
      'durationSeconds': 920.0,
      'recTime': '16:30:45',
      'size': '14.2 MB',
      'recordingUrl': 'https://storage.googleapis.com/govia-vault/recordings/bond_signing_rossi.mp4',
      'notes': 'Co-signer agreement and collateral documents verified and signed. Processed court submission.',
    },
  ];

  @override
  void onInit() {
    super.onInit();
    recordings.assignAll(_defaultRecordings);
    loadHistory();
  }

  Future<void> loadHistory({bool silent = false}) async {
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

        final completed = items.where((m) {
          final status = m['status']?.toString().toUpperCase() ?? '';
          return status == 'COMPLETED';
        }).toList();

        if (completed.isNotEmpty) {
          final mapped = completed.map((m) {
            String topic = m['topic']?.toString() ?? 'Bail Consultation';
            String client = m['callerName']?.toString() ?? 'Client';
            String recUrl = m['recordingUrl']?.toString() ?? '';

            DateTime dt = DateTime.now();
            final startRaw = m['startTime'] ?? m['createdAt'];
            if (startRaw != null) {
              try {
                dt = DateTime.parse(startRaw.toString()).toLocal();
              } catch (_) {}
            }

            final durationMin = int.tryParse(m['durationMinutes']?.toString() ?? '15') ?? 15;
            final durationSec = durationMin * 60.0;

            return {
              'title': '$client - $topic',
              'date': DateFormat('MMMM dd, yyyy').format(dt),
              'time': DateFormat('h:mm a').format(dt),
              'duration': '${durationMin.toString().padLeft(2, '0')}:00',
              'durationSeconds': durationSec,
              'recTime': DateFormat('HH:mm:ss').format(dt),
              'size': '${(durationMin * 1.2).toStringAsFixed(1)} MB',
              'recordingUrl': recUrl.isNotEmpty ? recUrl : 'https://storage.googleapis.com/govia-vault/recordings/meeting_${m['_id'] ?? m['id']}.mp4',
              'notes': m['notes']?.toString() ?? 'Verified identity and bail evaluation record saved to cloud archive.',
            };
          }).toList();

          recordings.assignAll(mapped);
          if (selectedIndex.value >= recordings.length) {
            selectedIndex.value = 0;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading bail bondsman history: $e');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  String formatTime(double seconds) {
    final int min = (seconds / 60).floor();
    final int sec = (seconds % 60).floor();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void togglePlay() {
    isPlaying.toggle();
  }

  void toggleMute() {
    isMuted.toggle();
  }

  void selectVideo(int index) {
    if (index >= 0 && index < recordings.length) {
      selectedIndex.value = index;
      isPlaying.value = false;
      currentPosition.value = ((recordings[index]['durationSeconds'] as double?) ?? 300.0) * 0.5;
    }
  }

  void watchRecording() {
    if (recordings.isEmpty) return;
    final cur = recordings[selectedIndex.value];
    final url = cur['recordingUrl']?.toString() ?? '';
    final title = cur['title']?.toString() ?? 'Session Recording';
    if (url.isNotEmpty) {
      GoviaVideoPlayerView.open(
        url: url,
        title: title,
        subtitle: 'Bail Bondsman Consultation Evidence',
        date: cur['date']?.toString(),
      );
    } else {
      Helpers.showCustomSnackBar('No cloud recording URL is attached to this session.', type: SnackBarType.info);
    }
  }

  void copyRecordingUrl() {
    if (recordings.isEmpty) return;
    final cur = recordings[selectedIndex.value];
    final url = cur['recordingUrl']?.toString() ?? '';
    if (url.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: url));
      Helpers.showCustomSnackBar('Recording URL copied to clipboard!', type: SnackBarType.success);
    } else {
      Helpers.showCustomSnackBar('No cloud recording URL is attached to this session.', type: SnackBarType.info);
    }
  }
}
