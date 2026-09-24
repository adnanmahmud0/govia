import 'package:get/get.dart';
import 'package:gsabino365/module/attorney/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/attorney/home/controller/attorney_home_controller.dart';
import 'package:gsabino365/module/attorney/schedule/controller/attorney_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';
import 'package:gsabino365/module/attorney/notification/controller/attorney_notification_controller.dart';
import 'package:gsabino365/module/attorney/profile/controller/attorney_profile_controller.dart';

class AttorneyBottomNavBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AttorneyBottomNavBarController());
    Get.lazyPut(() => AttorneyHomeController(), fenix: true);
    Get.lazyPut(() => AttorneyScheduleController(), fenix: true);
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController(), fenix: true);
    Get.lazyPut(() => AttorneyNotificationController(), fenix: true);
    Get.lazyPut(() => AttorneyProfileController(), fenix: true);
  }
}
