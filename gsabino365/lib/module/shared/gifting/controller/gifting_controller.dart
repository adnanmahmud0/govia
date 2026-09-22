import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class GiftingController extends GetxController {
  void giftFamily() {
    Get.toNamed(AppRoutes.giftSafety);
  }

  void configureEnterprise() {
    Get.toNamed(AppRoutes.organizationDetails);
  }
}
