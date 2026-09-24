import 'package:get/get.dart';

class DoctorHistoryController extends GetxController {
  final RxBool isPlaying = false.obs;
  final RxDouble currentPosition = 380.0.obs; // starting position
  final RxBool isMuted = false.obs;
  final RxInt selectedIndex = 0.obs;

  final List<Map<String, dynamic>> recordings = [
    {
      'title': 'Robert Wilson - Emergency Consultation',
      'date': 'June 10, 2026',
      'time': '3:45 PM',
      'duration': '12:42',
      'durationSeconds': 762.0,
      'recTime': '15:45:22',
      'size': '12.4 MB',
      'notes': 'Consulted on stress verification protocols and immediate coping mechanisms. Recommended follow-up in 2 weeks.',
    },
    {
      'title': 'Jhon Doe - Standard Check-in',
      'date': 'June 08, 2026',
      'time': '11:15 AM',
      'duration': '08:10',
      'durationSeconds': 490.0,
      'recTime': '11:15:05',
      'size': '8.2 MB',
      'notes': 'Routine progress evaluation. Patient shows improvements in stress level index logs.',
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
