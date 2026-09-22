import 'package:get/get.dart';
import 'package:gsabino365/module/police/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/police/home/controller/police_home_controller.dart';
import 'package:gsabino365/module/police/schedule/controller/police_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';
import 'package:gsabino365/module/police/notification/controller/police_notification_controller.dart';
import 'package:gsabino365/module/police/profile/controller/police_profile_controller.dart';

class PoliceBottomNavBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PoliceBottomNavBarController());
    Get.lazyPut(() => PoliceHomeController(), fenix: true);
    Get.lazyPut(() => PoliceScheduleController(), fenix: true);
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController(), fenix: true);
    Get.lazyPut(() => PoliceNotificationController());
    Get.lazyPut(() => PoliceProfileController());
  }
}
