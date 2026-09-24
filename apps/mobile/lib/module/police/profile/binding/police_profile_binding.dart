import 'package:get/get.dart';
import 'package:gsabino365/module/police/profile/controller/police_profile_controller.dart';

class PoliceProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PoliceProfileController());
  }
}
