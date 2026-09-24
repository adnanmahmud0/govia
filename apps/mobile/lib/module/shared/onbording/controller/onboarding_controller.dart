import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/image_paths.dart';
import 'package:gsabino365/config/constants/storage_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/storage_service.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPageIndex = 0.obs;

  final List<OnboardingModel> onboardingPages = [
    OnboardingModel(
      image: ImagePaths.onboardingImage1,
      title: 'Your Voice is Your Shield',
      subtitle: 'Coming soon - upgrade "Hey\nGoVia Record"',
    ),
    OnboardingModel(
      image: ImagePaths.onboardingImage2,
      title: 'Live Expert Backup',
      subtitle: 'Get instant support from an Attorney and a\nMental Health Professional on a live call.',
    ),
    OnboardingModel(
      image: ImagePaths.onboardingImage3,
      title: 'Secure Evidence Vault',
      subtitle: 'Captured camera\'s list "coming\nsoon" upgrade',
    ),
  ];

  void onPageChanged(int index) {
    currentPageIndex.value = index;
  }

  Future<void> nextPage() async {
    if (currentPageIndex.value < onboardingPages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await finishOnboarding();
    }
  }

  Future<void> finishOnboarding() async {
    await StorageService.setBool(StorageConstants.onboardingSeen, true);
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

class OnboardingModel {
  final String image;
  final String title;
  final String subtitle;

  OnboardingModel({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
