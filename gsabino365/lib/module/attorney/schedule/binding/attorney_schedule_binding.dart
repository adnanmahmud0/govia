import 'package:get/get.dart';
import 'package:gsabino365/module/attorney/schedule/controller/attorney_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';

class AttorneyScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AttorneyScheduleController());
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController());
  }
}
