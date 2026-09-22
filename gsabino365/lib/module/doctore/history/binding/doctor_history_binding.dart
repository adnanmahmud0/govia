import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/history/controller/doctor_history_controller.dart';

class DoctorHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorHistoryController());
  }
}
