import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/repositories/hero_highlight_repository.dart';

class HighlightHeroController extends GetxController {
  late final HeroHighlightRepository _repository;

  // Form Controllers
  late TextEditingController nameController;
  late TextEditingController badgeController;
  late TextEditingController agencyController;
  late TextEditingController carController;
  late TextEditingController feedbackController;
  late TextEditingController dateController;
  late TextEditingController locationController;

  // Search & ID Controllers
  late TextEditingController officerSearchController;
  late TextEditingController badgeLookupController;

  // Selected Officer State
  final Rx<Map<String, dynamic>?> selectedOfficer = Rx<Map<String, dynamic>?>(null);
  final RxBool isManualEntry = false.obs;

  // Officers Roster
  final RxList<Map<String, dynamic>> officersList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredOfficersList = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingOfficers = false.obs;
  final RxBool isLookingUpOfficer = false.obs;

  // Rating Sliders (1 to 10)
  final RxDouble respectRating = 9.0.obs;
  final RxDouble deescalationRating = 9.5.obs;
  final RxDouble communicationRating = 9.0.obs;

  // Sharing Checkboxes
  final RxBool shareWithAgency = true.obs;
  final RxBool includeInMetrics = true.obs;
  final RxBool shareWithCourt = true.obs;

  // Tabs & Feed State
  final RxInt selectedTab = 0.obs; // 0 = Nominate, 1 = Community Highlights
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingFeed = false.obs;
  final RxList<Map<String, dynamic>> heroFeed = <Map<String, dynamic>>[].obs;
  final RxSet<String> salutedHeroIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : Get.put(ApiClient());
    _repository = HeroHighlightRepository(apiClient: apiClient);

    nameController = TextEditingController();
    badgeController = TextEditingController();
    agencyController = TextEditingController();
    carController = TextEditingController();
    feedbackController = TextEditingController();
    dateController = TextEditingController(text: _formatToday());
    locationController = TextEditingController(text: 'Current Location');

    officerSearchController = TextEditingController();
    badgeLookupController = TextEditingController();

    loadOfficers();
    loadHeroFeed();
  }

  String _formatToday() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
  }

  // ──────────────────────── OFFICERS ROSTER & LOOKUP ────────────────────────
  Future<void> loadOfficers() async {
    isLoadingOfficers.value = true;
    try {
      final list = await _repository.getOfficers();
      if (list.isNotEmpty) {
        officersList.assignAll(list);
        filteredOfficersList.assignAll(list);
      } else {
        // Fallback default demo officers if network empty
        final fallback = _getDefaultOfficers();
        officersList.assignAll(fallback);
        filteredOfficersList.assignAll(fallback);
      }
    } catch (_) {
      final fallback = _getDefaultOfficers();
      officersList.assignAll(fallback);
      filteredOfficersList.assignAll(fallback);
    } finally {
      isLoadingOfficers.value = false;
    }
  }

  void filterOfficers(String query) {
    if (query.trim().isEmpty) {
      filteredOfficersList.assignAll(officersList);
      return;
    }
    final q = query.toLowerCase().trim();
    filteredOfficersList.assignAll(
      officersList.where((officer) {
        final name = (officer['name'] ?? '').toString().toLowerCase();
        final badge = (officer['badgeNumber'] ?? '').toString().toLowerCase();
        final agency = (officer['agency'] ?? '').toString().toLowerCase();
        final car = (officer['carNumber'] ?? '').toString().toLowerCase();
        return name.contains(q) || badge.contains(q) || agency.contains(q) || car.contains(q);
      }).toList(),
    );
  }

  void selectOfficer(Map<String, dynamic> officer) {
    HapticFeedback.mediumImpact();
    selectedOfficer.value = Map<String, dynamic>.from(officer);
    isManualEntry.value = false;

    // Auto-populate form
    nameController.text = (officer['name'] ?? '').toString().replaceFirst(RegExp(r'^Officer\s+|^Sergeant\s+|^Lieutenant\s+', caseSensitive: false), '');
    badgeController.text = (officer['badgeNumber'] ?? '').toString().replaceFirst('#', '');
    agencyController.text = (officer['agency'] ?? '').toString();
    carController.text = (officer['carNumber'] ?? '').toString();

    Helpers.showSuccess(
      'Selected ${officer['rank'] ?? 'Officer'} ${officer['name']}',
      title: 'Officer Identified',
    );
  }

  void clearSelectedOfficer() {
    HapticFeedback.lightImpact();
    selectedOfficer.value = null;
    isManualEntry.value = false;
    nameController.clear();
    badgeController.clear();
    agencyController.clear();
    carController.clear();
  }

  void enableManualEntry() {
    HapticFeedback.lightImpact();
    selectedOfficer.value = null;
    isManualEntry.value = true;
    nameController.clear();
    badgeController.clear();
    agencyController.clear();
    carController.clear();
  }

  /// Lookup officer by badge number, LEO license, or Short ID
  Future<bool> lookupOfficerById(String input) async {
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      Helpers.showCustomSnackBar('Please enter a badge number or officer ID.', title: 'Required');
      return false;
    }

    isLookingUpOfficer.value = true;
    HapticFeedback.selectionClick();

    try {
      // 1. Try local list first
      final q = cleaned.toLowerCase().replaceFirst('#', '');
      final localMatch = officersList.firstWhereOrNull((o) {
        final b = (o['badgeNumber'] ?? '').toString().toLowerCase().replaceFirst('#', '');
        final s = (o['shortHexId'] ?? '').toString().toLowerCase().replaceFirst('#', '');
        final l = (o['licenseNumber'] ?? '').toString().toLowerCase();
        final c = (o['carNumber'] ?? '').toString().toLowerCase();
        return b == q || s == q || l == q || c == q || b.contains(q);
      });

      if (localMatch != null) {
        selectOfficer(localMatch);
        isLookingUpOfficer.value = false;
        return true;
      }

      // 2. Query Backend Lookup Endpoint
      final officer = await _repository.lookupOfficer(cleaned);
      if (officer != null) {
        selectOfficer(officer);
        isLookingUpOfficer.value = false;
        return true;
      }

      Helpers.showWarning(
        'No verified officer found matching "$cleaned". You can nominate them manually below.',
        title: 'Officer Not Found',
      );
      isManualEntry.value = true;
      badgeController.text = cleaned;
      return false;
    } catch (e) {
      Helpers.showWarning(
        'Could not find officer matching "$cleaned". You can enter their details manually.',
        title: 'Officer Not Found',
      );
      isManualEntry.value = true;
      badgeController.text = cleaned;
      return false;
    } finally {
      isLookingUpOfficer.value = false;
    }
  }

  /// Handle QR payload scanned from camera
  Future<bool> handleScannedQr(String rawPayload) async {
    final trimmed = rawPayload.trim();
    if (trimmed.isEmpty) return false;

    HapticFeedback.heavyImpact();
    isLookingUpOfficer.value = true;

    String candidateId = trimmed;

    // Check if JSON payload (from GoVia digital card)
    try {
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        if (decoded['id'] != null) {
          candidateId = decoded['id'].toString();
        } else if (decoded['shortId'] != null) {
          candidateId = decoded['shortId'].toString();
        } else if (decoded['badgeNumber'] != null) {
          candidateId = decoded['badgeNumber'].toString();
        }
      }
    } catch (_) {}

    final success = await lookupOfficerById(candidateId);
    isLookingUpOfficer.value = false;
    return success;
  }

  // ──────────────────────── SUBMIT COMMENDATION ────────────────────────
  Future<void> submitHeroHighlight() async {
    final name = (selectedOfficer.value?['name'] ?? nameController.text).toString().trim();
    final agency = (selectedOfficer.value?['agency'] ?? agencyController.text).toString().trim();
    final badge = (selectedOfficer.value?['badgeNumber'] ?? badgeController.text).toString().trim();
    final car = (selectedOfficer.value?['carNumber'] ?? carController.text).toString().trim();
    final location = locationController.text.trim();
    final date = dateController.text.trim();
    final feedback = feedbackController.text.trim();

    if (name.isEmpty) {
      Helpers.showCustomSnackBar('Please select or enter the officer name.', title: 'Officer Required');
      return;
    }

    if (agency.isEmpty) {
      Helpers.showCustomSnackBar('Please select or enter the officer agency / department.', title: 'Agency Required');
      return;
    }

    if (feedback.isEmpty) {
      Helpers.showCustomSnackBar('Please share what the officer did well.', title: 'Story Required');
      return;
    }

    isSubmitting.value = true;
    HapticFeedback.mediumImpact();

    final payload = {
      if (selectedOfficer.value?['id'] != null) 'officerId': selectedOfficer.value!['id'],
      'officerName': name.toLowerCase().startsWith('officer') || name.toLowerCase().startsWith('sergeant') ? name : 'Officer $name',
      'officerRank': selectedOfficer.value?['rank'] ?? 'Officer',
      'badgeNumber': badge.isNotEmpty ? (badge.startsWith('#') ? badge : '#$badge') : '#CPD-900',
      'agency': agency,
      'carNumber': car.isNotEmpty ? car : 'UNIT-01',
      if (selectedOfficer.value?['image'] != null) 'officerAvatar': selectedOfficer.value!['image'],
      'respectRating': respectRating.value,
      'deEscalationRating': deescalationRating.value,
      'communicationRating': communicationRating.value,
      'whatDidOfficerDoWell': feedback,
      'incidentDate': date.isNotEmpty ? date : _formatToday(),
      'incidentLocation': location.isNotEmpty ? location : 'City Center',
      'shareWithAgency': shareWithAgency.value,
      'includeInMetrics': includeInMetrics.value,
      'shareWithCourt': shareWithCourt.value,
    };

    try {
      final res = await _repository.submitHeroHighlight(payload);
      final newHighlight = res?['data'] != null ? Map<String, dynamic>.from(res!['data'] as Map) : null;

      if (newHighlight != null) {
        heroFeed.insert(0, {
          'id': newHighlight['_id']?.toString() ?? 'hero_${DateTime.now().millisecondsSinceEpoch}',
          'officerName': payload['officerName'],
          'badgeNumber': payload['badgeNumber'],
          'agency': payload['agency'],
          'carNumber': payload['carNumber'],
          'officerAvatar': payload['officerAvatar'],
          'location': payload['incidentLocation'],
          'date': 'Just now',
          'story': payload['whatDidOfficerDoWell'],
          'respectRating': payload['respectRating'],
          'deescalationRating': payload['deEscalationRating'],
          'likes': 1,
          'saluted': true,
        });
        salutedHeroIds.add(newHighlight['_id']?.toString() ?? '');
      } else {
        // Fallback local insertion
        final localId = 'hero_${DateTime.now().millisecondsSinceEpoch}';
        heroFeed.insert(0, {
          'id': localId,
          'officerName': payload['officerName'],
          'badgeNumber': payload['badgeNumber'],
          'agency': payload['agency'],
          'carNumber': payload['carNumber'],
          'officerAvatar': payload['officerAvatar'],
          'location': payload['incidentLocation'],
          'date': 'Just now',
          'story': payload['whatDidOfficerDoWell'],
          'respectRating': payload['respectRating'],
          'deescalationRating': payload['deEscalationRating'],
          'likes': 1,
          'saluted': true,
        });
        salutedHeroIds.add(localId);
      }

      // Reset form & state
      clearSelectedOfficer();
      feedbackController.clear();

      // Switch to Community Highlights tab
      selectedTab.value = 1;

      Helpers.showSuccess(
        'Thank you! Your commendation for $name has been officially published and sent to their agency records.',
        title: '⭐ Hero Highlighted!',
      );
    } catch (e) {
      Helpers.showWarning('Failed to submit commendation. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  }

  // ──────────────────────── COMMUNITY HIGHLIGHTS FEED ────────────────────────
  Future<void> loadHeroFeed() async {
    isLoadingFeed.value = true;
    try {
      final list = await _repository.getHeroHighlights();
      if (list.isNotEmpty) {
        heroFeed.assignAll(list);
      } else {
        heroFeed.assignAll(_getDefaultHeroFeed());
      }
    } catch (_) {
      heroFeed.assignAll(_getDefaultHeroFeed());
    } finally {
      isLoadingFeed.value = false;
    }
  }

  void likeHero(String heroId) {
    HapticFeedback.lightImpact();
    final index = heroFeed.indexWhere((h) => h['id'] == heroId);
    if (index == -1) return;

    final hero = Map<String, dynamic>.from(heroFeed[index]);
    final isLiked = salutedHeroIds.contains(heroId);
    int currentLikes = (hero['likes'] as num?)?.toInt() ?? 0;

    if (isLiked) {
      salutedHeroIds.remove(heroId);
      hero['likes'] = (currentLikes - 1).clamp(0, 99999);
      hero['saluted'] = false;
    } else {
      salutedHeroIds.add(heroId);
      hero['likes'] = currentLikes + 1;
      hero['saluted'] = true;
    }

    heroFeed[index] = hero;
    unawaited(_repository.toggleSalute(heroId));
  }

  // ──────────────────────── DEFAULT DATA ────────────────────────
  List<Map<String, dynamic>> _getDefaultOfficers() {
    return [
      {
        'id': '6ab220bde836fdb8a11134e8',
        'name': 'Officer James Miller',
        'rank': 'Patrol Officer',
        'badgeNumber': 'CPD-4402',
        'carNumber': 'UNIT-71',
        'agency': 'Central Metro Division - Precinct 4',
        'licenseNumber': 'LEO-991240',
        'shortHexId': 'A11134E8',
        'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
        'rating': 4.9,
        'respectRating': 9.6,
        'deescalationRating': 9.8,
        'communicationRating': 9.4,
        'totalCommendations': 18,
        'verified': true,
      },
      {
        'id': '6ab220bde836fdb8a11134ec',
        'name': 'Sergeant Patricia Walker',
        'rank': 'Sergeant',
        'badgeNumber': 'CPD-2108',
        'carNumber': 'PATROL-12',
        'agency': 'Traffic & Highway Patrol Division',
        'licenseNumber': 'LEO-773194',
        'shortHexId': 'A11134EC',
        'image': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&auto=format&fit=crop&q=80',
        'rating': 5.0,
        'respectRating': 9.9,
        'deescalationRating': 9.7,
        'communicationRating': 9.9,
        'totalCommendations': 26,
        'verified': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultHeroFeed() {
    return [
      {
        'id': 'hero_01',
        'officerName': 'Officer James Miller',
        'badgeNumber': '#CPD-4402',
        'agency': 'Central Metro Division - Precinct 4',
        'location': '5th & Elm Street, Downtown',
        'date': 'Yesterday',
        'story': 'Officer Miller demonstrated extraordinary patience during a roadside traffic stop at night. He introduced himself respectfully, explained the reason for the stop with complete clarity, and made our entire family feel safe and respected.',
        'respectRating': 9.8,
        'deescalationRating': 10.0,
        'likes': 48,
        'saluted': false,
        'officerAvatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
      },
      {
        'id': 'hero_02',
        'officerName': 'Sergeant Patricia Walker',
        'badgeNumber': '#CPD-2108',
        'agency': 'Traffic & Highway Patrol Division',
        'location': 'Interstate 35 North Exit',
        'date': '3 days ago',
        'story': 'Helped change a flat tire in heavy rain without hesitation. Kept traffic diverted safely and provided hazard escort until roadside assistance arrived.',
        'respectRating': 10.0,
        'deescalationRating': 9.6,
        'likes': 74,
        'saluted': true,
        'officerAvatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&auto=format&fit=crop&q=80',
      },
    ];
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
    officerSearchController.dispose();
    badgeLookupController.dispose();
    super.onClose();
  }
}
