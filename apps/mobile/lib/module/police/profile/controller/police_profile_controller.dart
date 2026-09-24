import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/widgets/user_qr_card_dialog.dart';
import 'package:gsabino365/data/models/user_model.dart';

class PoliceProfileController extends GetxController {
  final AuthService _authService = AuthService.to;

  final RxString activeRole = 'Police'.obs;

  final RxString name = 'Officer'.obs;
  final RxString badgeId = '772410-GT'.obs;
  final RxString officerTitle = 'Patrol Officer'.obs;
  final RxString department = 'Metropolitan Justice Agency'.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString languages = 'English'.obs;
  final RxString avatarUrl = ''.obs;
  final RxString shortHexId = ''.obs;
  final RxString fullId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ever<UserModel?>(_authService.currentUser, _syncUserData);
    _syncUserData(_authService.currentUser.value);
    _refreshProfile();
  }

  void _syncUserData(UserModel? user) {
    if (user == null) return;
    if (user.name != null && user.name!.isNotEmpty) name.value = user.name!;
    if (user.badgeNumber != null && user.badgeNumber!.isNotEmpty) {
      badgeId.value = user.badgeNumber!;
    }
    if (user.subRole != null && user.subRole!.isNotEmpty) {
      officerTitle.value = user.subRole!;
    }
    if (user.departmentOrPrecinct != null && user.departmentOrPrecinct!.isNotEmpty) {
      department.value = user.departmentOrPrecinct!;
    } else if (user.officeName != null && user.officeName!.isNotEmpty) {
      department.value = user.officeName!;
    }
    if (user.email != null && user.email!.isNotEmpty) email.value = user.email!;
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      phone.value = user.phoneNumber!;
    }
    if (user.languagesSpoken != null && user.languagesSpoken!.isNotEmpty) {
      languages.value = user.languagesSpoken!;
    }
    final img = user.image ?? user.profilePicture ?? '';
    if (img.isNotEmpty) {
      avatarUrl.value = ApiConstants.getFileUrl(img);
    }

    if (user.shortHexId != null && user.shortHexId!.isNotEmpty) {
      shortHexId.value = user.shortHexId!;
    }
    if (user.id != null && user.id!.isNotEmpty) {
      fullId.value = user.id!;
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final user = await _authService.fetchProfile();
      if (user != null) _syncUserData(user);
    } catch (_) {}
  }

  void copyHexId() {
    final idToCopy = shortHexId.value.isNotEmpty ? shortHexId.value : badgeId.value;
    Clipboard.setData(ClipboardData(text: idToCopy));
    Get.rawSnackbar(
      message: 'Copied Officer ID: #$idToCopy',
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1550A6),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showBailBondsmanDirectory(BuildContext context) {
    final List<Map<String, String>> agencies = [
      {
        'name': 'Liberty Bail Bonds 24/7',
        'license': 'BB-44912-OH',
        'phone': '(800) 555-2245',
        'coverage': 'County Detention & Metropolitan Jail',
        'status': 'Verified • Immediate Response',
      },
      {
        'name': 'Apex Justice Bail Services',
        'license': 'BB-99210-FD',
        'phone': '(888) 555-0199',
        'coverage': 'Statewide Holding & Municipal Courts',
        'status': 'Licensed Provider',
      },
      {
        'name': 'Guardian Angel Bail Agency',
        'license': 'BB-31209-GT',
        'phone': '(877) 555-0144',
        'coverage': 'Precincts 1–12 Rapid Processing',
        'status': 'On-Call Preferred Partner',
      },
    ];

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.monetization_on_rounded,
                    color: const Color(0xFF1550A6),
                    size: 24.sp,
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
                        'Licensed bondsmen approved for quick release',
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

  void openOfficerQrDialog({int initialTabIndex = 0}) {
    UserQrCardDialog.show(
      userName: name.value.isNotEmpty ? name.value : 'Officer',
      userRole: 'POLICE',
      shortHexId: shortHexId.value.isNotEmpty ? shortHexId.value : (badgeId.value.isNotEmpty ? badgeId.value : '00000000'),
      fullId: fullId.value.isNotEmpty ? fullId.value : 'N/A',
      avatarUrl: avatarUrl.value.isNotEmpty ? avatarUrl.value : null,
      initialTabIndex: initialTabIndex,
    );
  }

  void openQrDialog({int initialTabIndex = 0}) => openOfficerQrDialog(initialTabIndex: initialTabIndex);
  void openQrScanner() => openOfficerQrDialog(initialTabIndex: 1);

  void confirmLogout() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: const Color(0xFFDC2626),
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to end your active officer shift and log out?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44.h,
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 44.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          _authService.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

