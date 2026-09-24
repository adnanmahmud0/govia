import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlanModel {
  final String id;
  final String title;
  final String price;
  final String description;
  final List<String> features;
  final String? badge;

  PlanModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.features,
    this.badge,
  });
}

class SubscriptionController extends GetxController {
  final RxString selectedPlanId = 'basic'.obs;

  final List<PlanModel> plans = [
    PlanModel(
      id: 'free',
      title: 'Community Free',
      price: '\$0',
      description: 'Entry-level access for low-income and youth users',
      features: [
        'Sponsored by churches, nonprofits, foundations',
        'Know Your Rights library',
        'Anonymous encounter tip line',
      ],
      badge: 'Free',
    ),
    PlanModel(
      id: 'basic',
      title: 'Basic Plan',
      price: '\$9',
      description: 'Essential features for individual users',
      features: [
        'All Community Free features',
        'Unlimited affidavit filings',
        'Priority support',
        'Basic legal resources',
      ],
      badge: 'Most Popular',
    ),
    PlanModel(
      id: 'preferred',
      title: 'Preferred Attorney',
      price: '\$200-600',
      description: 'Professional features for practicing attorneys',
      features: [
        'All Basic Plan features',
        'Client management tools',
        'Advanced legal templates',
      ],
    ),
    PlanModel(
      id: 'enterprise',
      title: 'Enterprise Attorney',
      price: 'Custom price',
      description: 'Complete solution for law firms and enterprises',
      features: [
        'All Preferred features',
        'Multi-user team management',
        'Advanced analytics dashboard',
        'Custom integrations',
      ],
      badge: 'Enterprise',
    ),
  ];

  void selectPlan(String id) {
    selectedPlanId.value = id;
  }

  void subscribe() {
    final selectedPlan = plans.firstWhere((p) => p.id == selectedPlanId.value);
    Get.snackbar(
      'Subscription Success',
      'You have successfully subscribed to ${selectedPlan.title}!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF059669),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}
