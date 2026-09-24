import 'package:get/get.dart';
import 'package:gsabino365/module/shared/subscription/controller/subscription_controller.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SubscriptionController());
  }
}
