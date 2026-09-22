import 'package:get/get.dart';
import 'package:gsabino365/module/police/birds_eye/controller/police_crisis_management_controller.dart';

class PoliceCrisisManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PoliceCrisisManagementController());
  }
}
