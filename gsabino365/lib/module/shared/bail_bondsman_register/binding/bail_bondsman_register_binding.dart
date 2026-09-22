import 'package:get/get.dart';
import 'package:gsabino365/module/shared/bail_bondsman_register/controller/bail_bondsman_register_controller.dart';

class BailBondsmanRegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(BailBondsmanRegisterController());
  }
}
