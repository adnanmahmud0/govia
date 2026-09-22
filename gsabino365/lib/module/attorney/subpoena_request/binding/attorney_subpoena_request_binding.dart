import 'package:get/get.dart';
import 'package:gsabino365/module/attorney/subpoena_request/controller/attorney_subpoena_request_controller.dart';

class AttorneySubpoenaRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AttorneySubpoenaRequestController());
  }
}
