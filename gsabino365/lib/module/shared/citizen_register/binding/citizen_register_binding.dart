import 'package:get/get.dart';
import 'package:gsabino365/module/shared/citizen_register/controller/citizen_register_controller.dart';

class CitizenRegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CitizenRegisterController());
  }
}
