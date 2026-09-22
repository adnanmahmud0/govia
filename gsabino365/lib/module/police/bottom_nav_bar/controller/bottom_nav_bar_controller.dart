import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';

class PoliceBottomNavBarController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxString activeRole = 'Police'.obs;

  AuthService get _authService {
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>();
    }
    return AuthService.to;
  }

  void changeTabIndex(int index) {
    if (index >= 0 && index <= 3) {
      selectedIndex.value = index;
    }
  }

  void goToHome() => changeTabIndex(0);
  void goToSchedule() => changeTabIndex(1);
  void goToNotifications() => changeTabIndex(2);
  void goToProfile() => changeTabIndex(3);

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
