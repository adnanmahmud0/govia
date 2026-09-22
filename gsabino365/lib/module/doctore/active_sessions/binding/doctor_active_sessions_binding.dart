import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/active_sessions/controller/doctor_active_sessions_controller.dart';

class DoctorActiveSessionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorActiveSessionsController());
  }
}
