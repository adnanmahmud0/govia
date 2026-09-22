import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';
import 'package:gsabino365/data/models/user_model.dart';

class AttorneyProfileController extends GetxController {
  late final AuthService _authService;

  final RxString activeRole = 'Attorney'.obs;
  final RxString name = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString languages = 'English'.obs;
  final RxString licensedStates = 'Nationwide'.obs;
  final RxString shortHexId = ''.obs;
  final RxString fullId = ''.obs;
  final RxString avatarUrl = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();

    ever<UserModel?>(_authService.currentUser, _syncUserData);
    _syncUserData(_authService.currentUser.value);

    refreshProfile();
  }

  void _syncUserData(UserModel? user) {
    if (user == null) return;

    name.value = user.name?.isNotEmpty == true ? user.name! : 'Attorney';
    email.value = user.email ?? '';
    phone.value = user.phoneNumber ?? '';
    avatarUrl.value = user.image ?? user.profilePicture ?? '';
    if (user.languagesSpoken != null && user.languagesSpoken!.isNotEmpty) {
      languages.value = user.languagesSpoken!;
    }
    if (user.licensedStatesToPractice != null &&
        user.licensedStatesToPractice!.isNotEmpty) {
      licensedStates.value = user.licensedStatesToPractice!;
    }
    if (user.role != null && user.role!.isNotEmpty) {
      activeRole.value = user.role!;
    }

    fullId.value = user.id ?? '';
    shortHexId.value = user.shortHexId ?? '';
  }

  Future<void> updateProfileImage() async {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Change Profile Photo',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Choose how you would like to select your photo',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: const Color(0xFF1550A6),
                    size: 22.sp,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(
                  'Use your device camera',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Get.back();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              Divider(height: 1.h, color: const Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: const Color(0xFF1550A6),
                    size: 22.sp,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(
                  'Select an existing photo',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Get.back();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) return;

      isUploadingImage.value = true;
      Get.rawSnackbar(
        message: 'Uploading profile image...',
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1550A6),
        snackPosition: SnackPosition.BOTTOM,
      );

      final file = File(picked.path);
      final updatedUser = await _authService.updateProfileImage(file);

      if (updatedUser != null) {
        avatarUrl.value = updatedUser.image ?? updatedUser.profilePicture ?? '';
        Get.snackbar(
          'Success',
          'Profile image updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1550A6),
          colorText: Colors.white,
          margin: EdgeInsets.all(16.w),
          borderRadius: 12.r,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Upload Failed',
          'Could not upload profile image. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          margin: EdgeInsets.all(16.w),
          borderRadius: 12.r,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to select or upload image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: EdgeInsets.all(16.w),
        borderRadius: 12.r,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> refreshProfile() async {
    isLoading.value = true;
    try {
      final user = await _authService.fetchProfile();
      if (user != null) {
        _syncUserData(user);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void openQrDialog({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: name.value.isNotEmpty ? name.value : 'Attorney',
      userRole: activeRole.value.isNotEmpty ? activeRole.value : 'Attorney',
      shortHexId: shortHexId.value.isNotEmpty ? shortHexId.value : '00000000',
      fullId: fullId.value.isNotEmpty ? fullId.value : 'N/A',
      avatarUrl: avatarUrl.value.isNotEmpty ? ApiConstants.getFileUrl(avatarUrl.value) : null,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrScanner() => openQrDialog(initialTabIndex: 1);

  void copyHexId() {
    final hexId = shortHexId.value;
    if (hexId.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: hexId));
      Get.rawSnackbar(
        message: 'Copied Short Hex ID: #$hexId',
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E3A8A),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
