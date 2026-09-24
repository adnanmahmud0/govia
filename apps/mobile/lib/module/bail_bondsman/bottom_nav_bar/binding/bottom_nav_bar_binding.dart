import 'package:get/get.dart';
import 'package:gsabino365/module/bail_bondsman/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/bail_bondsman/home/controller/bail_bondsman_home_controller.dart';
import 'package:gsabino365/module/bail_bondsman/schedule/controller/bail_bondsman_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';
import 'package:gsabino365/module/bail_bondsman/notification/controller/bail_bondsman_notification_controller.dart';
import 'package:gsabino365/module/bail_bondsman/profile/controller/bail_bondsman_profile_controller.dart';

class BailBondsmanBottomNavBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(BailBondsmanBottomNavBarController());
    Get.lazyPut(() => BailBondsmanHomeController(), fenix: true);
    Get.lazyPut(() => BailBondsmanScheduleController(), fenix: true);
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController(), fenix: true);
    Get.lazyPut(() => BailBondsmanNotificationController());
    Get.lazyPut(() => BailBondsmanProfileController());
  }
}
