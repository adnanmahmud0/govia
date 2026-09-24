import 'package:get/get.dart';
import 'package:gsabino365/module/shared/preferred_providers/controller/preferred_providers_controller.dart';

class PreferredProvidersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PreferredProvidersController>(
      () => PreferredProvidersController(),
    );
  }
}
