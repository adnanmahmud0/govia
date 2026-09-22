import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/module/attorney/notification/controller/attorney_notification_controller.dart';

class AttorneyBottomNavBarController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxString activeRole = 'Attorney'.obs;

  int get unreadNotificationsCount {
    if (Get.isRegistered<AttorneyNotificationController>()) {
      return Get.find<AttorneyNotificationController>().unreadCount;
    }
    return 0;
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  void goToHome() => changeTabIndex(0);
  void goToSchedule() => changeTabIndex(1);
  void goToNotifications() => changeTabIndex(2);
  void goToProfile() => changeTabIndex(3);

  Future<void> logout() async {
    if (Get.isRegistered<AuthService>()) {
      await AuthService.to.logout();
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
