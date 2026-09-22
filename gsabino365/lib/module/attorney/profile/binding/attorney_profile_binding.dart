import 'package:get/get.dart';
import 'package:gsabino365/module/attorney/profile/controller/attorney_profile_controller.dart';

class AttorneyProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AttorneyProfileController());
  }
}
