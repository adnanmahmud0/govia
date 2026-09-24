import 'package:get/get.dart';
import 'package:gsabino365/module/bail_bondsman/schedule/controller/bail_bondsman_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';

class BailBondsmanScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BailBondsmanScheduleController());
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController());
  }
}
