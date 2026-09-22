import 'package:get/get.dart';

class AttorneyEvidenceVaultController extends GetxController {
  final RxBool isPlaying = false.obs;
  final RxDouble currentPosition = 862.0.obs; // 14 mins 22 secs
  final double totalDuration = 1690.0; // 28 mins 10 secs
  final RxBool isMuted = false.obs;

  final RxInt selectedIndex = 0.obs;

  final List<Map<String, dynamic>> recordings = [
    {
      'title': 'Street Incident Recording',
      'date': 'April 25, 2026',
      'time': '2:45 PM',
      'duration': '28:10',
      'durationSeconds': 1690.0,
      'recTime': '14:22:45',
      'size': '12.4 MB',
    },
    {
      'title': 'Traffic Stop Evidence Video',
      'date': 'April 22, 2026',
      'time': '11:15 AM',
      'duration': '15:40',
      'durationSeconds': 940.0,
      'recTime': '11:15:32',
      'size': '8.2 MB',
    },
    {
      'title': 'Client Consultation Record',
      'date': 'April 15, 2026',
      'time': '4:30 PM',
      'duration': '45:12',
      'durationSeconds': 2712.0,
      'recTime': '16:30:10',
      'size': '24.7 MB',
    },
  ];

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
    selectedIndex.value = index;
    isPlaying.value = false;
    currentPosition.value = (recordings[index]['durationSeconds'] as double) * 0.5; // start mid-way for demo
  }
}
