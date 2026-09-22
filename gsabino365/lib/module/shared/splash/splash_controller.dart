import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/config/constants/storage_constants.dart';
import 'package:gsabino365/core/services/storage_service.dart';
import 'package:gsabino365/core/services/auth_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 2));

    final authService = Get.find<AuthService>();
    final hasSession = await authService.restoreSession();

    if (hasSession) {
      final role = authService.currentRole.value;
      final targetRoute = getDashboardForRole(role);
      Get.offAllNamed(targetRoute);
      return;
    }

    // Check onboarding status
    final onboardingSeen =
        await StorageService.getBool(StorageConstants.onboardingSeen) ?? false;

    if (!onboardingSeen) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  static String getDashboardForRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ATTORNEY':
        return AppRoutes.attorneyDashboard;
      case 'MENTAL_HEALTH_PROFESSIONAL':
        return AppRoutes.doctorDashboard;
      case 'POLICE':
        return AppRoutes.policeDashboard;
      case 'BAIL_BONDSMAN':
        return AppRoutes.bailBondsmanDashboard;
      case 'CITIZEN':
      case 'USER':
      default:
        return AppRoutes.citizenDashboard;
    }
  }
}
