import 'package:get/get.dart';
import 'package:gsabino365/module/police/schedule/controller/police_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';

class PoliceScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PoliceScheduleController());
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController());
  }
}
