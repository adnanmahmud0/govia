import 'package:get/get.dart';
import 'package:gsabino365/module/police/home/controller/police_home_controller.dart';

class PoliceHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PoliceHomeController());
  }
}
