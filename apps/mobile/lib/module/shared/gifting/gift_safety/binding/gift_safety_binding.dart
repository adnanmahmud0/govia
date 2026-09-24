import 'package:get/get.dart';
import 'package:gsabino365/module/shared/gifting/gift_safety/controller/gift_safety_controller.dart';

class GiftSafetyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GiftSafetyController());
  }
}
