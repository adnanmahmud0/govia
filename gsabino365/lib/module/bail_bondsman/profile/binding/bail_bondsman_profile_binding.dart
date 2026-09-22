import 'package:get/get.dart';
import 'package:gsabino365/module/bail_bondsman/profile/controller/bail_bondsman_profile_controller.dart';

class BailBondsmanProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BailBondsmanProfileController());
  }
}
