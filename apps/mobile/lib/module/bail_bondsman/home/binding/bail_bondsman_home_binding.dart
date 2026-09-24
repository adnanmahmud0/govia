import 'package:get/get.dart';
import 'package:gsabino365/module/bail_bondsman/home/controller/bail_bondsman_home_controller.dart';

class BailBondsmanHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BailBondsmanHomeController());
  }
}
