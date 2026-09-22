import 'package:get/get.dart';

class PoliceBirdsEyeController extends GetxController {
  final RxBool isPlaying1 = false.obs;
  final RxBool isPlaying2 = false.obs;
  final RxBool isPlaying3 = false.obs;

  final RxDouble position1 = 45.0.obs;
  final RxDouble position2 = 45.0.obs;
  final RxDouble position3 = 45.0.obs;

  final double totalDuration1 = 150.0; // 02:30
  final double totalDuration2 = 312.0; // 05:12
  final double totalDuration3 = 150.0; // 02:30

  String formatTime(double seconds) {
    final int min = (seconds / 60).floor();
    final int sec = (seconds % 60).floor();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void togglePlay1() => isPlaying1.toggle();
  void togglePlay2() => isPlaying2.toggle();
  void togglePlay3() => isPlaying3.toggle();
}
