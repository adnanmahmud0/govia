import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/citizen/profile/controller/citizen_profile_controller.dart';
import 'package:gsabino365/module/attorney/profile/controller/attorney_profile_controller.dart';
import 'package:gsabino365/module/doctore/profile/controller/doctor_profile_controller.dart';
import 'package:gsabino365/module/police/profile/controller/police_profile_controller.dart';
import 'package:gsabino365/module/bail_bondsman/profile/controller/bail_bondsman_profile_controller.dart';

class PersonalInfoController extends GetxController {
  late final AuthService _authService;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController languagesController;
  late TextEditingController licensedStatesController;

  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    final user = _authService.currentUser.value;

    String initialName = user?.name ?? '';
    String initialEmail = user?.email ?? '';
    String initialPhone = user?.phoneNumber ?? '';
    String initialLanguages = user?.languagesSpoken ?? '';
    String initialLicensedStates = user?.licensedStatesToPractice ?? '';

    if (Get.isRegistered<CitizenProfileController>()) {
      final pc = Get.find<CitizenProfileController>();
      if (initialName.isEmpty) initialName = pc.name.value;
      if (initialEmail.isEmpty) initialEmail = pc.email.value;
      if (initialPhone.isEmpty) initialPhone = pc.phone.value;
      if (initialLanguages.isEmpty) initialLanguages = pc.languages.value;
    } else if (Get.isRegistered<AttorneyProfileController>()) {
      final pc = Get.find<AttorneyProfileController>();
      if (initialName.isEmpty) initialName = pc.name.value;
      if (initialEmail.isEmpty) initialEmail = pc.email.value;
      if (initialPhone.isEmpty) initialPhone = pc.phone.value;
      if (initialLanguages.isEmpty) initialLanguages = pc.languages.value;
      if (initialLicensedStates.isEmpty) {
        initialLicensedStates = pc.licensedStates.value;
      }
    } else if (Get.isRegistered<DoctorProfileController>()) {
      final pc = Get.find<DoctorProfileController>();
      if (initialName.isEmpty) initialName = pc.name.value;
      if (initialEmail.isEmpty) initialEmail = pc.email.value;
      if (initialPhone.isEmpty) initialPhone = pc.phone.value;
      if (initialLanguages.isEmpty) initialLanguages = pc.languages.value;
    } else if (Get.isRegistered<PoliceProfileController>()) {
      final pc = Get.find<PoliceProfileController>();
      if (initialName.isEmpty) initialName = pc.name.value;
      if (initialEmail.isEmpty) initialEmail = pc.email.value;
      if (initialPhone.isEmpty) initialPhone = pc.phone.value;
      if (initialLanguages.isEmpty) initialLanguages = pc.languages.value;
    } else if (Get.isRegistered<BailBondsmanProfileController>()) {
      final pc = Get.find<BailBondsmanProfileController>();
      if (initialName.isEmpty) initialName = pc.name.value;
      if (initialEmail.isEmpty) initialEmail = pc.email.value;
      if (initialPhone.isEmpty) initialPhone = pc.phone.value;
      if (initialLanguages.isEmpty) initialLanguages = pc.languages.value;
    }

    nameController = TextEditingController(text: initialName);
    emailController = TextEditingController(text: initialEmail);
    phoneController = TextEditingController(text: initialPhone);
    languagesController = TextEditingController(text: initialLanguages);
    licensedStatesController = TextEditingController(
      text: initialLicensedStates,
    );
  }

  Future<void> saveChanges() async {
    final nameText = nameController.text.trim();
    final emailText = emailController.text.trim();
    final phoneText = phoneController.text.trim();
    final languagesText = languagesController.text.trim();
    final licensedStatesText = licensedStatesController.text.trim();

    if (nameText.isEmpty) {
      Helpers.showError('Name cannot be empty', title: 'Validation Error');
      return;
    }
    if (emailText.isEmpty) {
      Helpers.showError('Email cannot be empty', title: 'Validation Error');
      return;
    }

    isSaving.value = true;

    try {
      final updateData = <String, dynamic>{
        'name': nameText,
        'email': emailText,
        'phoneNumber': phoneText,
        'languagesSpoken': languagesText,
      };

      if (Get.isRegistered<AttorneyProfileController>()) {
        updateData['licensedStatesToPractice'] = licensedStatesText;
      }

      await _authService.updateProfile(updateData);

      // Synchronize controllers
      if (Get.isRegistered<CitizenProfileController>()) {
        final pc = Get.find<CitizenProfileController>();
        pc.name.value = nameText;
        pc.email.value = emailText;
        pc.phone.value = phoneText;
        pc.languages.value = languagesText;
      } else if (Get.isRegistered<AttorneyProfileController>()) {
        final pc = Get.find<AttorneyProfileController>();
        pc.name.value = nameText;
        pc.email.value = emailText;
        pc.phone.value = phoneText;
        pc.languages.value = languagesText;
        pc.licensedStates.value = licensedStatesText;
      } else if (Get.isRegistered<DoctorProfileController>()) {
        final pc = Get.find<DoctorProfileController>();
        pc.name.value = nameText;
        pc.email.value = emailText;
        pc.phone.value = phoneText;
        pc.languages.value = languagesText;
      } else if (Get.isRegistered<PoliceProfileController>()) {
        final pc = Get.find<PoliceProfileController>();
        pc.name.value = nameText;
        pc.email.value = emailText;
        pc.phone.value = phoneText;
        pc.languages.value = languagesText;
      } else if (Get.isRegistered<BailBondsmanProfileController>()) {
        final pc = Get.find<BailBondsmanProfileController>();
        pc.name.value = nameText;
        pc.email.value = emailText;
        pc.phone.value = phoneText;
        pc.languages.value = languagesText;
      }

      isSaving.value = false;

      Get.back();
      Helpers.showSuccess(
        'Personal Information updated successfully.',
        title: 'Success',
      );
    } catch (e) {
      isSaving.value = false;
      Helpers.showError(
        'Failed to save personal information: $e',
        title: 'Error',
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    languagesController.dispose();
    licensedStatesController.dispose();
    super.onClose();
  }
}
