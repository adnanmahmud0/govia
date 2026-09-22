import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/dispatch/controller/doctor_dispatch_controller.dart';

class DoctorDispatchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorDispatchController());
  }
}
