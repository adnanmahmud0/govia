import 'package:get/get.dart';
import 'package:gsabino365/module/shared/onbording/controller/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(OnboardingController());
  }
}
