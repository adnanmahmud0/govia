import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';

class CitizenBottomNavBarController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxString activeRole = 'Citizen'.obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  void goToHome() => changeTabIndex(0);
  void goToSchedule() => changeTabIndex(1);
  void goToCommunity() => changeTabIndex(2);
  void goToVault() => changeTabIndex(3);
  void goToProfile() => changeTabIndex(4);

  Future<void> logout() async {
    if (Get.isRegistered<AuthService>()) {
      await AuthService.to.logout();
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
