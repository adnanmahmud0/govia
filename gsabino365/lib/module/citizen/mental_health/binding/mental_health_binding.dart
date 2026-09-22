import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/mental_health/controller/mental_health_controller.dart';

class MentalHealthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MentalHealthController>(() => MentalHealthController());
  }
}
