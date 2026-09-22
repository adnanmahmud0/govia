import 'package:get/get.dart';
import 'package:gsabino365/module/shared/splash/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
