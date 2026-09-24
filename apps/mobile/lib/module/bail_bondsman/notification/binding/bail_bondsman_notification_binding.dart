import 'package:get/get.dart';
import 'package:gsabino365/module/bail_bondsman/notification/controller/bail_bondsman_notification_controller.dart';

class BailBondsmanNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BailBondsmanNotificationController());
  }
}
