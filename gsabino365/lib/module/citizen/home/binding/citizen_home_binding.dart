import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/home/controller/citizen_home_controller.dart';

class CitizenHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CitizenHomeController());
  }
}
