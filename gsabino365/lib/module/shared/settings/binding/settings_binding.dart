import 'package:get/get.dart';
import 'package:gsabino365/module/shared/settings/controller/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettingsController());
  }
}
