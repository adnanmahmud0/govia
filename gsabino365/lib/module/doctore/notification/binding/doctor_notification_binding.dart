import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/notification/controller/doctor_notification_controller.dart';

class DoctorNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorNotificationController());
  }
}
