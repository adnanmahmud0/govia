import 'package:get/get.dart';
import 'package:gsabino365/module/shared/register/controller/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RegisterController());
  }
}
