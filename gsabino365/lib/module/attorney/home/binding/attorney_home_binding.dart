import 'package:get/get.dart';
import 'package:gsabino365/module/attorney/home/controller/attorney_home_controller.dart';

class AttorneyHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AttorneyHomeController());
  }
}
