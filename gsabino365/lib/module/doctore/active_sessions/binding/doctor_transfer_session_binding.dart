import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/active_sessions/controller/doctor_transfer_session_controller.dart';

class DoctorTransferSessionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorTransferSessionController());
  }
}
