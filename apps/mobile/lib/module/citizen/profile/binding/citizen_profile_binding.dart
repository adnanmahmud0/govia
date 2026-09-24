import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/profile/controller/citizen_profile_controller.dart';

class CitizenProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CitizenProfileController());
  }
}
