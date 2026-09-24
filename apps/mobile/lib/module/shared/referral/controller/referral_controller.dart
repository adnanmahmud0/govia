import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/module/citizen/profile/controller/citizen_profile_controller.dart';
import 'package:gsabino365/module/attorney/profile/controller/attorney_profile_controller.dart';
import 'package:gsabino365/module/doctore/profile/controller/doctor_profile_controller.dart';
import 'package:gsabino365/module/police/profile/controller/police_profile_controller.dart';
import 'package:gsabino365/module/bail_bondsman/profile/controller/bail_bondsman_profile_controller.dart';

class ReferralController extends GetxController {
  late String referralLink;
  final RxInt totalPoints = 1250.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<CitizenProfileController>()) {
      referralLink = 'govia.io/invite/sarahj77';
    } else if (Get.isRegistered<AttorneyProfileController>()) {
      referralLink = 'govia.io/invite/jhonj88';
    } else if (Get.isRegistered<DoctorProfileController>()) {
      referralLink = 'govia.io/invite/doctorjhon88';
    } else if (Get.isRegistered<PoliceProfileController>()) {
      referralLink = 'govia.io/invite/sterling77';
    } else if (Get.isRegistered<BailBondsmanProfileController>()) {
      referralLink = 'govia.io/invite/wilson99';
    } else {
      referralLink = 'govia.io/invite/share';
    }
  }

  void copyReferralLink() {
    Clipboard.setData(ClipboardData(text: referralLink));
    Get.snackbar(
      'Copied',
      'Referral link copied to clipboard!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }
}
