import 'package:get/get.dart';
import 'package:gsabino365/module/shared/police_register/controller/police_register_controller.dart';

class PoliceRegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PoliceRegisterController());
  }
}
