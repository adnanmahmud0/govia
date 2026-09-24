import 'package:get/get.dart';
import 'package:gsabino365/core/services/auth_service.dart';

class DoctorBottomNavBarController extends GetxController {
  AuthService get _authService => Get.find<AuthService>();

  final RxInt selectedIndex = 0.obs;
  final RxString activeRole = 'Mental Health Professional'.obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  void goToHome() => changeTabIndex(0);
  void goToSchedule() => changeTabIndex(1);
  void goToNotifications() => changeTabIndex(2);
  void goToProfile() => changeTabIndex(3);

  void logout() {
    _authService.logout();
  }
}

