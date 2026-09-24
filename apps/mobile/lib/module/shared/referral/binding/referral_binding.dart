import 'package:get/get.dart';
import 'package:gsabino365/module/shared/referral/controller/referral_controller.dart';

class ReferralBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ReferralController());
  }
}
