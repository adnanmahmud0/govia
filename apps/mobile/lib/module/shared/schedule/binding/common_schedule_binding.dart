import 'package:get/get.dart';
import 'package:gsabino365/module/shared/schedule/controller/common_schedule_controller.dart';

class CommonScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommonScheduleController>(
      () => CommonScheduleController(),
      fenix: true,
    );
  }
}
