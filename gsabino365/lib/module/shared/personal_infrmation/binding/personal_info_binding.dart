import 'package:get/get.dart';
import 'package:gsabino365/module/shared/personal_infrmation/controller/personal_info_controller.dart';

class PersonalInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PersonalInfoController());
  }
}
