import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/home/controller/doctor_home_controller.dart';

class DoctorHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorHomeController());
  }
}
