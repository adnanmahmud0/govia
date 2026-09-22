import 'package:get/get.dart';
import 'package:gsabino365/module/bail_bondsman/active_requests/controller/bail_bondsman_active_requests_controller.dart';

class BailBondsmanActiveRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BailBondsmanActiveRequestsController>(
      () => BailBondsmanActiveRequestsController(),
    );
  }
}
