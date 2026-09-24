import 'package:get/get.dart';
import 'package:gsabino365/module/attorney/notification/controller/attorney_notification_controller.dart';

class AttorneyNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AttorneyNotificationController());
  }
}
