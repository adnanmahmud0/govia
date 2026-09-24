import 'package:get/get.dart';
import 'package:gsabino365/module/police/birds_eye/controller/police_birds_eye_controller.dart';

class PoliceBirdsEyeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PoliceBirdsEyeController>(() => PoliceBirdsEyeController());
  }
}
