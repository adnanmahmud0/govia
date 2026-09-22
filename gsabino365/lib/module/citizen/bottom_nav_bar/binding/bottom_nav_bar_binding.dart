import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/bottom_nav_bar/controller/bottom_nav_bar_controller.dart';
import 'package:gsabino365/module/citizen/home/controller/citizen_home_controller.dart';
import 'package:gsabino365/module/citizen/schedule/controller/citizen_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';
import 'package:gsabino365/module/citizen/community/controller/citizen_community_controller.dart';
import 'package:gsabino365/module/citizen/vault/controller/citizen_vault_controller.dart';
import 'package:gsabino365/module/citizen/profile/controller/citizen_profile_controller.dart';

class CitizenBottomNavBarBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CitizenBottomNavBarController());
    Get.lazyPut(() => CitizenHomeController(), fenix: true);
    Get.lazyPut(() => CitizenScheduleController(), fenix: true);
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController(), fenix: true);
    Get.lazyPut(() => CitizenCommunityController(), fenix: true);
    Get.lazyPut(() => CitizenVaultController(), fenix: true);
    Get.lazyPut(() => CitizenProfileController(), fenix: true);
  }
}
