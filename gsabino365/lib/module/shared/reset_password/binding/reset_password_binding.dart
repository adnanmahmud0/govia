import 'package:get/get.dart';
import 'package:gsabino365/module/shared/reset_password/controller/reset_password_controller.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ResetPasswordController());
  }
}
