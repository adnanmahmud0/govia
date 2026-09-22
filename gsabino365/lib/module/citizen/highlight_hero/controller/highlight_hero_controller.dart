import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class HighlightHeroController extends GetxController {
  late final ApiClient _apiClient;

  late TextEditingController nameController;
  late TextEditingController badgeController;
  late TextEditingController agencyController;
  late TextEditingController carController;
  late TextEditingController feedbackController;
  late TextEditingController dateController;
  late TextEditingController locationController;

  final RxDouble respectRating = 8.0.obs;
  final RxDouble deescalationRating = 9.0.obs;
  final RxDouble communicationRating = 8.0.obs;

  final RxBool shareWithAgency = true.obs;
  final RxBool includeInMetrics = true.obs;
  final RxBool shareWithCourt = true.obs;

  final RxInt selectedTab = 0.obs; // 0 = Nominate, 1 = Community Feed
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingFeed = false.obs;

  final RxList<Map<String, dynamic>> heroFeed = <Map<String, dynamic>>[].obs;
  final RxSet<String> likedHeroIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : Get.put(ApiClient());

    nameController = TextEditingController();
    badgeController = TextEditingController();
    agencyController = TextEditingController();
    carController = TextEditingController();
    feedbackController = TextEditingController();
    dateController = TextEditingController(text: '10/10/2025');
    locationController = TextEditingController(text: '123 Main Street, Downtown');

    _loadInitialHeroFeed();
  }

  void _loadInitialHeroFeed() {
    heroFeed.assignAll([
      {
        'id': 'hero_01',
        'officerName': 'Officer Marcus Rivera',
        'badgeNumber': '#4412',
        'agency': 'Metro Police Department',
        'location': '5th & Elm Street, Downtown',
        'date': 'Yesterday',
        'story': 'Officer Rivera demonstrated exceptional patience and calm during a stressful traffic stop at night. He introduced himself clearly, de-escalated tension immediately, and made our family feel completely safe and respected.',
        'respectRating': 9.5,
        'deescalationRating': 10.0,
        'likes': 42,
        'saluted': false,
      },
      {
        'id': 'hero_02',
        'officerName': 'Sergeant Angela Davis',
        'badgeNumber': '#2981',
        'agency': 'Highway Patrol District 4',
        'location': 'Interstate 35 North Exit',
        'date': '3 days ago',
        'story': 'Helped change a blown tire in pouring rain without hesitation. Ensured children inside vehicle remained calm and provided hazard escort until roadside assistance arrived.',
        'respectRating': 10.0,
        'deescalationRating': 9.0,
        'likes': 68,
        'saluted': true,
      },
      {
        'id': 'hero_03',
        'officerName': 'Officer Thomas Wright',
        'badgeNumber': '#1105',
        'agency': 'County Sheriff Office',
        'location': 'Community Center Plaza',
        'date': 'Last week',
        'story': 'Spent 20 minutes explaining local juvenile curfew procedures peacefully to teens outside recreation center rather than issuing punitive citations. True community leader.',
        'respectRating': 9.0,
        'deescalationRating': 9.5,
        'likes': 31,
        'saluted': false,
      },
    ]);
  }

  Future<void> submitHeroHighlight() async {
    final name = nameController.text.trim();
    final agency = agencyController.text.trim();
    final badge = badgeController.text.trim();
    final location = locationController.text.trim();
    final date = dateController.text.trim();
    final feedback = feedbackController.text.trim();

    if (name.isEmpty) {
      Helpers.showCustomSnackBar(
        'Please enter the officer name.',
        title: 'Required Field',
        type: SnackBarType.warning,
      );
      return;
    }

    if (agency.isEmpty) {
      Helpers.showCustomSnackBar(
        'Please enter the agency name.',
        title: 'Required Field',
        type: SnackBarType.warning,
      );
      return;
    }

    isSubmitting.value = true;
    HapticFeedback.mediumImpact();

    // Prepare payload
    final newHero = {
      'id': 'hero_${DateTime.now().millisecondsSinceEpoch}',
      'officerName': 'Officer $name',
      'badgeNumber': badge.isNotEmpty ? '#$badge' : '#${(1000 + DateTime.now().millisecond)}',
      'agency': agency,
      'location': location.isNotEmpty ? location : 'City Center',
      'date': date.isNotEmpty ? date : 'Today',
      'story': feedback.isNotEmpty
          ? feedback
          : 'Highlighted for outstanding professionalism, fair communication, and community de-escalation conduct.',
      'respectRating': respectRating.value,
      'deescalationRating': deescalationRating.value,
      'likes': 1,
      'saluted': true,
    };

    // Best-effort send to backend API
    try {
      await _apiClient.postData(
        ApiConstants.communityResources,
        {
          'type': 'HIGHLIGHT_HERO',
          'title': 'Commendation: Officer $name',
          'description': newHero['story'],
          'metadata': {
            'officerName': name,
            'badgeNumber': badge,
            'agency': agency,
            'respectRating': respectRating.value,
            'deescalationRating': deescalationRating.value,
            'communicationRating': communicationRating.value,
          },
        },
      );
    } catch (_) {}

    isSubmitting.value = false;

    // Add to feed & switch tab
    heroFeed.insert(0, newHero);
    likedHeroIds.add(newHero['id'] as String);
    selectedTab.value = 1;

    // Clear form
    nameController.clear();
    badgeController.clear();
    agencyController.clear();
    carController.clear();
    feedbackController.clear();

    Helpers.showSuccess(
      'Thank you! Your commendation for Officer $name has been submitted to the community feed.',
      title: 'Hero Highlighted!',
    );
  }

  void likeHero(String heroId) {
    HapticFeedback.lightImpact();
    final index = heroFeed.indexWhere((h) => h['id'] == heroId);
    if (index == -1) return;

    final hero = Map<String, dynamic>.from(heroFeed[index]);
    final isLiked = likedHeroIds.contains(heroId);
    int currentLikes = (hero['likes'] as num?)?.toInt() ?? 0;

    if (isLiked) {
      likedHeroIds.remove(heroId);
      hero['likes'] = (currentLikes - 1).clamp(0, 99999);
      hero['saluted'] = false;
    } else {
      likedHeroIds.add(heroId);
      hero['likes'] = currentLikes + 1;
      hero['saluted'] = true;
    }

    heroFeed[index] = hero;

    // Best-effort sync like to backend
    try {
      unawaited(_apiClient.patchData(
        '${ApiConstants.communityResources}/$heroId/like',
        {},
      ));
    } catch (_) {}
  }

  @override
  void onClose() {
    nameController.dispose();
    badgeController.dispose();
    agencyController.dispose();
    carController.dispose();
    feedbackController.dispose();
    dateController.dispose();
    locationController.dispose();
    super.onClose();
  }
}

