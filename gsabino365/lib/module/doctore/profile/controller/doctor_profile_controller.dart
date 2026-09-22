import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';
import 'package:gsabino365/data/models/user_model.dart';

class DoctorProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final RxString activeRole = 'Mental Health Professional'.obs;
  final RxString name = 'Dr. Emily Chen, PsyD'.obs;
  final RxString email = 'doctor@govia.com'.obs;
  final RxString phone = '+1 (555) 017-3399'.obs;
  final RxString assignedNumber = 'CR-CHEN-01'.obs;
  final RxString doctorId = ''.obs;
  final RxString languages = 'English, Mandarin'.obs;
  final RxString avatarUrl = ''.obs;

  final RxBool isUploadingImage = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever<UserModel?>(_authService.currentUser, _syncUserData);
    _syncUserData(_authService.currentUser.value);
  }

  void _syncUserData(UserModel? user) {
    if (user != null) {
      if (user.name != null && user.name!.isNotEmpty) name.value = user.name!;
      if (user.email != null && user.email!.isNotEmpty) email.value = user.email!;
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) phone.value = user.phoneNumber!;
      if (user.assignedNumber != null && user.assignedNumber!.isNotEmpty) {
        assignedNumber.value = user.assignedNumber!;
      } else if (user.badgeNumber != null && user.badgeNumber!.isNotEmpty) {
        assignedNumber.value = user.badgeNumber!;
      } else if (user.shortHexId != null && user.shortHexId!.isNotEmpty) {
        assignedNumber.value = user.shortHexId!.toUpperCase();
      }
      doctorId.value = user.id ?? '';
      if (user.languagesSpoken != null && user.languagesSpoken!.isNotEmpty) languages.value = user.languagesSpoken!;
      avatarUrl.value = user.image ?? user.profilePicture ?? '';
    }
  }

  void copyAssignedNumber() {
    Clipboard.setData(ClipboardData(text: assignedNumber.value));
    Get.rawSnackbar(
      message: 'Copied License ID: #${assignedNumber.value}',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1550A6),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openDoctorQrCard({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: name.value,
      userRole: 'Mental Health Professional',
      shortHexId: assignedNumber.value,
      fullId: doctorId.value,
      avatarUrl: avatarUrl.value.isNotEmpty ? avatarUrl.value : null,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrDialog({int initialTabIndex = 0}) => openDoctorQrCard(initialTabIndex: initialTabIndex);
  void openQrScanner() => openDoctorQrCard(initialTabIndex: 1);
  void copyHexId() => copyAssignedNumber();

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

  void showBailBondsmenDirectory() {
    final List<Map<String, String>> agencies = [
      {
        'name': 'Apex Bail Bonds & Legal Support',
        'license': 'BB-849201',
        'phone': '(555) 234-5678',
        'coverage': 'Countywide • 24/7 Response',
        'status': 'Verified Fast Release',
      },
      {
        'name': 'Golden Gate Bail Services',
        'license': 'BB-192844',
        'phone': '(555) 345-6789',
        'coverage': 'District 1 - 5 • Immediate Dispatch',
        'status': 'Verified Fast Release',
      },
      {
        'name': 'Liberty & Trust Bail Agents',
        'license': 'BB-672109',
        'phone': '(555) 456-7890',
        'coverage': 'Downtown Precincts',
        'status': 'Verified Fast Release',
      },
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monetization_on_rounded,
                    color: const Color(0xFF1550A6),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authorized Bail Bondsman Network',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Licensed bondsmen approved for client release coordination',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...agencies.map((agency) {
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agency['name']!,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Lic: ${agency['license']} • ${agency['coverage']}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              agency['status']!,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF1550A6)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: agency['phone']!));
                        Get.back();
                        Get.rawSnackbar(
                          message: 'Copied ${agency['name']} phone: ${agency['phone']}',
                          backgroundColor: const Color(0xFF1550A6),
                          duration: const Duration(seconds: 2),
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 8.h),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void confirmLogout() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Log Out',
          style: GoogleFonts.inter(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your Mental Health Professional account?',
          style: GoogleFonts.inter(
            fontSize: 13.5.sp,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _authService.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
