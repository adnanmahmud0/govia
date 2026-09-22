import 'package:get/get.dart';
import 'package:gsabino365/config/routes/app_pages.dart';

enum UserRole {
  citizen,
  attorney,
  mentalHealth,
  police,
  bailBondsman,
}

class RegisterController extends GetxController {
  // Currently selected role, defaults to citizen
  final rxSelectedRole = Rx<UserRole>(UserRole.citizen);

  UserRole get selectedRole => rxSelectedRole.value;

  void selectRole(UserRole role) {
    rxSelectedRole.value = role;
  }

  void onNonCitizenSupportPressed() {
    Get.snackbar(
      'Support',
      'Non-Citizen Support requested. We will guide you shortly.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onContinuePressed() {
    if (rxSelectedRole.value == UserRole.citizen) {
      Get.toNamed(AppRoutes.citizenRegister);
    } else if (rxSelectedRole.value == UserRole.attorney) {
      Get.toNamed(AppRoutes.attorneyRegister);
    } else if (rxSelectedRole.value == UserRole.mentalHealth) {
      Get.toNamed(AppRoutes.mentalHealthRegister);
    } else if (rxSelectedRole.value == UserRole.police) {
      Get.toNamed(AppRoutes.policeRegister);
    } else if (rxSelectedRole.value == UserRole.bailBondsman) {
      Get.toNamed(AppRoutes.bailBondsmanRegister);
    } else {
      final roleName = rxSelectedRole.value.toString().split('.').last;
      Get.snackbar(
        'Sign Up',
        'Continuing registration as ${roleName.capitalizeFirst}. Form coming soon!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
