import 'package:get/get.dart';
import 'package:gsabino365/module/shared/forgot_password/controller/forgot_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ForgotPasswordController());
  }
}
