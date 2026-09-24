import 'package:get/get.dart';
import 'package:gsabino365/module/shared/attorney_register/controller/attorney_register_controller.dart';

class AttorneyRegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AttorneyRegisterController());
  }
}
