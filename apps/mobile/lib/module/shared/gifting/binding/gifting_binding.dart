import 'package:get/get.dart';
import 'package:gsabino365/module/shared/gifting/controller/gifting_controller.dart';

class GiftingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GiftingController());
  }
}
