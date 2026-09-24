import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/notification/controller/citizen_notification_controller.dart';

class CitizenNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CitizenNotificationController());
  }
}
