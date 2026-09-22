import 'package:get/get.dart';
import 'package:gsabino365/module/police/notification/controller/police_notification_controller.dart';

class PoliceNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PoliceNotificationController());
  }
}
