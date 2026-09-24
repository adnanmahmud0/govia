import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/profile/controller/doctor_profile_controller.dart';

class DoctorProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorProfileController());
  }
}
