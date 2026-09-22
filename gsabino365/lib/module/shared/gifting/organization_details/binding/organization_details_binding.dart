import 'package:get/get.dart';
import 'package:gsabino365/module/shared/gifting/organization_details/controller/organization_details_controller.dart';

class OrganizationDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OrganizationDetailsController());
  }
}
