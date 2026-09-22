import 'package:get/get.dart';
import 'package:gsabino365/module/shared/login/controller/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(LoginController());
  }
}
