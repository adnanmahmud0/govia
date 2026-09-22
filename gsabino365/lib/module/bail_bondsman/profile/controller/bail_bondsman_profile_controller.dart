import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';

class BailBondsmanProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final RxString activeRole = 'Bail Bondsman'.obs;

  final RxString name = 'Dana Morgan'.obs;
  final RxString email = 'bailbonds@govia.com'.obs;
  final RxString phone = '+1 (555) 011-9988'.obs;
  final RxString languages = 'English'.obs;
  final RxString licenseNumber = 'BB-882910'.obs;
  final RxString companyName = 'Govia Bail & Surety'.obs;
  final RxString businessAddress = 'Ohio, USA'.obs;
  final RxString avatarUrl = ''.obs;

  String get shortHexId {
    final user = _authService.currentUser.value;
    if (user?.shortHexId != null && user!.shortHexId!.isNotEmpty) {
      return user.shortHexId!;
    }
    final id = user?.id?.trim() ?? '';
    if (id.length >= 8) {
      return id.substring(id.length - 8).toUpperCase();
    } else if (id.isNotEmpty) {
      return id.toUpperCase();
    }
    return '882910BB';
  }

  String get fullId {
    return _authService.currentUser.value?.id?.trim() ?? licenseNumber.value;
  }

  @override
  void onInit() {
    super.onInit();
    _syncUserData(_authService.currentUser.value);
    ever(_authService.currentUser, _syncUserData);
  }

  void _syncUserData(dynamic user) {
    if (user != null) {
      if (user.name != null && user.name!.isNotEmpty) name.value = user.name!;
      if (user.email != null && user.email!.isNotEmpty) email.value = user.email!;
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) phone.value = user.phoneNumber!;
      if (user.languagesSpoken != null && user.languagesSpoken!.isNotEmpty) languages.value = user.languagesSpoken!;
      if (user.licenseNumber != null && user.licenseNumber!.isNotEmpty) {
        licenseNumber.value = user.licenseNumber!;
      } else if (user.assignedNumber != null && user.assignedNumber!.isNotEmpty) {
        licenseNumber.value = user.assignedNumber!;
      }
      if (user.companyName != null && user.companyName!.isNotEmpty) companyName.value = user.companyName!;
      if (user.businessAddress != null && user.businessAddress!.isNotEmpty) businessAddress.value = user.businessAddress!;

      final img = user.image ?? user.profilePicture;
      if (img != null && img.isNotEmpty) {
        avatarUrl.value = ApiConstants.getFileUrl(img);
      }
    }
  }

  void openQrDialog({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: name.value,
      userRole: 'Bail Bondsman',
      shortHexId: shortHexId,
      fullId: fullId,
      avatarUrl: avatarUrl.value.isNotEmpty ? avatarUrl.value : null,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrScanner() => openQrDialog(initialTabIndex: 1);

  void copyHexId() {
    final hexId = shortHexId;
    Clipboard.setData(ClipboardData(text: hexId));
    Get.rawSnackbar(
      message: 'Copied Short Hex ID: #$hexId',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1550A6),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void logout() {
    _authService.logout();
  }
}
