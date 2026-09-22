import 'package:get/get.dart';
import 'package:gsabino365/module/doctore/dispatch/controller/doctor_request_community_controller.dart';

class DoctorRequestCommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DoctorRequestCommunityController());
  }
}
