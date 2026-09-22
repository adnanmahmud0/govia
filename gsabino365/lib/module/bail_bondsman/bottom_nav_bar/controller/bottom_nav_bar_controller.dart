import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

class BailBondsmanBottomNavBarController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxString activeRole = 'Bail Bondsman'.obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  void logout() {
    Get.offAllNamed(AppRoutes.login);
  }
}
