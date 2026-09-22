import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/doctore/home/controller/doctor_home_controller.dart';
import 'package:gsabino365/module/doctore/schedule/controller/doctor_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';
import 'package:gsabino365/module/doctore/notification/controller/doctor_notification_controller.dart';
import 'package:gsabino365/module/doctore/profile/controller/doctor_profile_controller.dart';

class DoctorBottomNavBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DoctorBottomNavBarController());
    Get.lazyPut(() => DoctorHomeController(), fenix: true);
    Get.lazyPut(() => DoctorScheduleController(), fenix: true);
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController(), fenix: true);
    Get.lazyPut(() => DoctorNotificationController(), fenix: true);
    Get.lazyPut(() => DoctorProfileController(), fenix: true);
  }
}
