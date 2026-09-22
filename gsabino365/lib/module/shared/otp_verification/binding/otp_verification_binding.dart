import 'package:get/get.dart';
import 'package:gsabino365/module/shared/otp_verification/controller/otp_verification_controller.dart';

class OtpVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(OtpVerificationController());
  }
}
