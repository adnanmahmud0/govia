import 'package:get/get.dart';
import 'package:gsabino365/module/shared/mental_health_register/controller/mental_health_register_controller.dart';

class MentalHealthRegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MentalHealthRegisterController());
  }
}
