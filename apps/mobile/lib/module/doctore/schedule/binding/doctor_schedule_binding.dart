import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/schedule/controller/doctor_schedule_controller.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';

class DoctorScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorScheduleController());
    Get.lazyPut<CommonScheduleController>(() => CommonScheduleController());
  }
}
