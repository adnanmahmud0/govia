import 'package:get/get.dart';
import 'package:gsabino365/module/shared/govia_ai/controller/govia_ai_controller.dart';

class GoviaAiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GoviaAiController());
  }
}
