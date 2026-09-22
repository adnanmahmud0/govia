import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorTransferSessionController extends GetxController {
  final RxString searchQuery = ''.obs;

  // Mock list of professionals to transfer to
  final List<Map<String, dynamic>> professionals = [
    {
      'id': '1',
      'name': 'Dr. Emily Watson',
      'role': 'MHP Specialist',
      'license': 'MHP-987654',
      'avatar': 'assets/images/user_avatar.png',
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Dr. Marcus Chen',
      'role': 'MHP Specialist',
      'license': 'MHP-123456',
      'avatar': 'assets/images/doctor_avatar.png',
      'isOnline': true,
    },
    {
      'id': '3',
      'name': 'Dr. Emily Watson',
      'role': 'MHP Specialist',
      'license': 'MHP-789012',
      'avatar': 'assets/images/user_avatar.png',
      'isOnline': true,
    },
  ];

  List<Map<String, dynamic>> get filteredProfessionals {
    if (searchQuery.value.isEmpty) {
      return professionals;
    }
    return professionals
        .where((p) => p['name']
            .toString()
            .toLowerCase()
            .contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void joinSession(Map<String, dynamic> prof) {
    Get.snackbar(
      'Session Transferred',
      'Successfully joined/transferred session to ${prof['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1550A6),
      colorText: Colors.white,
    );
  }
}
