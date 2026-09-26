import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/services/auth_service.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/data/models/provider_directory_item.dart';
import 'package:gsabino365/data/repositories/provider_payment_repository.dart';
import 'package:gsabino365/module/citizen/profile/controller/citizen_profile_controller.dart';
import 'package:gsabino365/module/shared/widgets/stripe_webview_modal.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PreferredProvidersController extends GetxController {
  late final AuthService _authService;
  late final ApiClient _apiClient;

  // Selected provider profiles
  final Rxn<Map<String, dynamic>> attorneyProfile = Rxn<Map<String, dynamic>>();
  final Rxn<Map<String, dynamic>> bailBondsmanProfile = Rxn<Map<String, dynamic>>();

  // Backward-compatible text controllers if referenced elsewhere
  final attorneyController = TextEditingController();
  final bailBondsmanController = TextEditingController();
  final directorySearchController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isLookingUp = false.obs;

  // Marketplace & Payments
  late final ProviderPaymentRepository providerPaymentRepo;
  final RxList<ProviderDirectoryItem> directoryProviders = <ProviderDirectoryItem>[].obs;
  final RxList<ProviderDirectoryItem> filteredProviders = <ProviderDirectoryItem>[].obs;
  final RxBool isLoadingDirectory = false.obs;
  final RxBool isProcessingCheckout = false.obs;

  // Active coverage dates
  final Rxn<DateTime> attorneyActiveUntil = Rxn<DateTime>();
  final Rxn<DateTime> bailBondsmanActiveUntil = Rxn<DateTime>();

  // Recent chat contacts cache
  final RxList<Map<String, dynamic>> recentContacts = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingContacts = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = Get.find<AuthService>();
    _apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : Get.put(ApiClient());
    providerPaymentRepo = ProviderPaymentRepository(apiClient: _apiClient);
    _loadInitialData();
  }

  void _loadInitialData() {
    final user = _authService.currentUser.value;
    String attorney = user?.preferredAttorney?.trim() ?? '';
    String bailBondsman = user?.preferredBailBondsman?.trim() ?? '';

    attorneyActiveUntil.value = user?.preferredAttorneyActiveUntil;
    bailBondsmanActiveUntil.value = user?.preferredBailBondsmanActiveUntil;

    // Ignore legacy dummy values so newly created accounts or accounts without providers remain empty
    if (attorney == 'John Doe Law Firm') attorney = '';
    if (bailBondsman == 'Dana Bail Bonds') bailBondsman = '';

    // If citizen profile controller has values, fallback to it
    if (attorney.isEmpty && Get.isRegistered<CitizenProfileController>()) {
      final pc = Get.find<CitizenProfileController>();
      final pcAttorney = pc.preferredAttorney.value.trim();
      if (pcAttorney.isNotEmpty && pcAttorney != 'John Doe Law Firm') {
        attorney = pcAttorney;
      }
    }
    if (bailBondsman.isEmpty && Get.isRegistered<CitizenProfileController>()) {
      final pc = Get.find<CitizenProfileController>();
      final pcBail = pc.preferredBailBondsman.value.trim();
      if (pcBail.isNotEmpty && pcBail != 'Dana Bail Bonds') {
        bailBondsman = pcBail;
      }
    }

    if (attorney.isNotEmpty) {
      attorneyController.text = attorney;
      attorneyProfile.value = {
        'name': attorney,
        'role': 'ATTORNEY',
        'connected': true,
      };
      // Try background lookup to load avatar if attorney is an ID or short code
      _enrichExistingProfile(attorney, forAttorney: true);
    } else {
      attorneyProfile.value = null;
      attorneyController.clear();
    }

    if (bailBondsman.isNotEmpty) {
      bailBondsmanController.text = bailBondsman;
      bailBondsmanProfile.value = {
        'name': bailBondsman,
        'role': 'BAIL_BONDSMAN',
        'connected': true,
      };
      _enrichExistingProfile(bailBondsman, forAttorney: false);
    } else {
      bailBondsmanProfile.value = null;
      bailBondsmanController.clear();
    }
  }

  Future<void> _enrichExistingProfile(String identifier, {required bool forAttorney}) async {
    try {
      final res = await _apiClient.getData(ApiConstants.userLookup(identifier));
      if (res.statusCode == 200 && res.data?['data'] != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        final profile = {
          'id': data['_id']?.toString() ?? data['id']?.toString() ?? identifier,
          'name': data['name']?.toString() ?? identifier,
          'image': data['profilePicture']?.toString() ?? data['image']?.toString() ?? '',
          'role': data['role']?.toString() ?? (forAttorney ? 'ATTORNEY' : 'BAIL_BONDSMAN'),
          'phoneNumber': data['phoneNumber']?.toString() ?? '',
          'connected': true,
        };
        if (forAttorney) {
          attorneyProfile.value = profile;
        } else {
          bailBondsmanProfile.value = profile;
        }
      }
    } catch (_) {}
  }

  Future<void> refreshProviders() async {
    await _authService.getProfile();
    _loadInitialData();
    await _fetchRecentContacts();
  }

  // ──────────────────────── AUTO-SAVE LOGIC ────────────────────────

  Future<void> setProvider(Map<String, dynamic> profile, {required bool forAttorney}) async {
    final name = (profile['name'] ?? profile['userName'] ?? 'Connected Provider').toString();
    final enrichedProfile = Map<String, dynamic>.from(profile);
    enrichedProfile['name'] = name;
    enrichedProfile['connected'] = true;
    enrichedProfile['connectedAt'] = DateTime.now().toIso8601String();

    if (forAttorney) {
      attorneyProfile.value = enrichedProfile;
      attorneyController.text = name;
    } else {
      bailBondsmanProfile.value = enrichedProfile;
      bailBondsmanController.text = name;
    }

    await _autoSave();

    Helpers.showSuccess(
      '$name has been connected and saved.',
      title: forAttorney ? 'Attorney Connected' : 'Bail Bondsman Connected',
    );
  }

  Future<void> disconnectProvider({required bool forAttorney}) async {
    if (forAttorney) {
      attorneyProfile.value = null;
      attorneyController.clear();
    } else {
      bailBondsmanProfile.value = null;
      bailBondsmanController.clear();
    }

    await _autoSave();

    Helpers.showSuccess(
      'Provider disconnected and saved.',
      title: 'Removed',
    );
  }

  Future<void> _autoSave() async {
    final attorneyText = attorneyProfile.value?['name'] ?? attorneyController.text.trim();
    final bailBondsmanText = bailBondsmanProfile.value?['name'] ?? bailBondsmanController.text.trim();

    isSaving.value = true;
    try {
      final updateData = {
        'preferredAttorney': attorneyText,
        'preferredBailBondsman': bailBondsmanText,
      };

      await _authService.updateProfile(updateData);

      if (Get.isRegistered<CitizenProfileController>()) {
        final pc = Get.find<CitizenProfileController>();
        pc.preferredAttorney.value = attorneyText;
        pc.preferredBailBondsman.value = bailBondsmanText;
      }
    } catch (e) {
      debugPrint('Error auto-saving preferred providers: $e');
    } finally {
      isSaving.value = false;
    }
  }

  // ──────────────────────── ACTION 1: SCAN QR CODE ────────────────────────

  void openQrScanner({required bool forAttorney}) {
    bool hasScanned = false;
    final scannerController = MobileScannerController();

    Get.bottomSheet(
      Container(
        height: 480,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    forAttorney ? 'Scan Attorney QR' : 'Scan Bail Bondsman QR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () {
                      scannerController.dispose();
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      child: MobileScanner(
                        controller: scannerController,
                        onDetect: (capture) {
                          if (hasScanned) return;
                          final barcode = capture.barcodes.firstOrNull;
                          if (barcode != null && barcode.rawValue != null) {
                            hasScanned = true;
                            HapticFeedback.heavyImpact();
                            scannerController.stop();
                            scannerController.dispose();
                            Get.back();
                            _processScannedValue(barcode.rawValue!, forAttorney: forAttorney);
                          }
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Text(
                'Point camera at the provider\'s GoVia digital ID card QR code',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _processScannedValue(String rawValue, {required bool forAttorney}) async {
    String resolvedName = rawValue.trim();
    String? resolvedId;
    String? resolvedImage;
    String? resolvedRole;

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        resolvedName = decoded['name']?.toString() ?? decoded['userName']?.toString() ?? resolvedName;
        resolvedId = decoded['id']?.toString() ?? decoded['_id']?.toString();
        resolvedImage = decoded['image']?.toString() ?? decoded['profilePicture']?.toString();
        resolvedRole = decoded['role']?.toString();
      }
    } catch (_) {}

    if (resolvedId != null && resolvedId.isNotEmpty) {
      try {
        final res = await _apiClient.getData(ApiConstants.userLookup(resolvedId));
        if (res.statusCode == 200 && res.data?['data'] != null) {
          final data = res.data['data'] as Map<String, dynamic>;
          resolvedName = data['name']?.toString() ?? resolvedName;
          resolvedImage = data['profilePicture']?.toString() ?? data['image']?.toString() ?? resolvedImage;
          resolvedRole = data['role']?.toString() ?? resolvedRole;
        }
      } catch (_) {}
    }

    final profile = {
      'id': resolvedId ?? '',
      'name': resolvedName,
      'image': resolvedImage ?? '',
      'role': resolvedRole ?? (forAttorney ? 'ATTORNEY' : 'BAIL_BONDSMAN'),
      'connected': true,
    };

    setProvider(profile, forAttorney: forAttorney);
  }

  // ──────────────────────── ACTION 2: LOOKUP USER ID ────────────────────────

  void openIdLookupDialog({required bool forAttorney}) {
    final inputCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_search_rounded, color: Color(0xFF1550A6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    forAttorney ? 'Add Attorney by ID' : 'Add Bail Bondsman by ID',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the provider\'s short hex ID, account ID, or phone number to link:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: inputCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. A1B2C3 or user ID',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1550A6), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1550A6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () async {
                      final id = inputCtrl.text.trim();
                      if (id.isEmpty) return;
                      Get.back();
                      await _executeLookup(id, forAttorney: forAttorney);
                    },
                    child: const Text('Lookup & Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeLookup(String identifier, {required bool forAttorney}) async {
    try {
      isLookingUp.value = true;
      final response = await _apiClient.getData(ApiConstants.userLookup(identifier));

      if (response.statusCode == 200 && response.data?['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final profile = {
          'id': data['_id']?.toString() ?? data['id']?.toString() ?? identifier,
          'name': data['name']?.toString() ?? identifier,
          'image': data['profilePicture']?.toString() ?? data['image']?.toString() ?? '',
          'role': data['role']?.toString() ?? (forAttorney ? 'ATTORNEY' : 'BAIL_BONDSMAN'),
          'phoneNumber': data['phoneNumber']?.toString() ?? '',
          'connected': true,
        };
        setProvider(profile, forAttorney: forAttorney);
      } else {
        final profile = {
          'id': identifier,
          'name': identifier,
          'role': forAttorney ? 'ATTORNEY' : 'BAIL_BONDSMAN',
          'connected': true,
        };
        setProvider(profile, forAttorney: forAttorney);
      }
    } catch (_) {
      final profile = {
        'id': identifier,
        'name': identifier,
        'role': forAttorney ? 'ATTORNEY' : 'BAIL_BONDSMAN',
        'connected': true,
      };
      setProvider(profile, forAttorney: forAttorney);
    } finally {
      isLookingUp.value = false;
    }
  }

  // ──────────────────────── ACTION 3: FROM RECENT CHAT CONTACTS ─────────────

  Future<void> openRecentContactsSheet({required bool forAttorney}) async {
    await _fetchRecentContacts();

    Get.bottomSheet(
      Container(
        height: 520,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forAttorney ? 'Select Preferred Attorney' : 'Select Preferred Bail Bondsman',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap a contact to automatically link and save',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: Obx(() {
                if (isLoadingContacts.value) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1550A6)));
                }

                if (recentContacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No recent chat contacts found',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use QR scan or User ID to link your provider',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: recentContacts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final contact = recentContacts[idx];
                    final name = contact['name']?.toString() ?? 'Contact';
                    final role = contact['role']?.toString() ?? 'Provider';
                    final avatar = contact['image']?.toString() ?? contact['profilePicture']?.toString();

                    return InkWell(
                      onTap: () {
                        Get.back();
                        setProvider(contact, forAttorney: forAttorney);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.1),
                              backgroundImage: (avatar != null && avatar.isNotEmpty)
                                  ? NetworkImage(ApiConstants.getFileUrl(avatar))
                                  : null,
                              child: (avatar == null || avatar.isEmpty)
                                  ? Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Color(0xFF1550A6), fontWeight: FontWeight.w700),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    role,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1550A6)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _fetchRecentContacts() async {
    try {
      isLoadingContacts.value = true;
      final response = await _apiClient.getData(ApiConstants.conversations);

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data['data'];
        List convs = [];
        if (raw is List) {
          convs = raw;
        } else if (raw is Map && raw['data'] is List) {
          convs = raw['data'] as List;
        }

        final myId = _authService.currentUser.value?.id ?? '';
        final Set<String> seenIds = {};
        final List<Map<String, dynamic>> extractedContacts = [];

        for (final item in convs) {
          if (item is Map) {
            final participants = item['participants'];
            if (participants is List) {
              for (final p in participants) {
                if (p is Map) {
                  final pid = p['_id']?.toString() ?? p['id']?.toString() ?? '';
                  if (pid.isNotEmpty && pid != myId && !seenIds.contains(pid)) {
                    seenIds.add(pid);
                    extractedContacts.add(Map<String, dynamic>.from(p));
                  }
                }
              }
            }
          }
        }

        recentContacts.assignAll(extractedContacts);
      }
    } catch (_) {
    } finally {
      isLoadingContacts.value = false;
    }
  }

  bool isCoverageActive({required bool forAttorney}) {
    final expiry = forAttorney ? attorneyActiveUntil.value : bailBondsmanActiveUntil.value;
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now());
  }

  int getCoverageRemainingDays({required bool forAttorney}) {
    final expiry = forAttorney ? attorneyActiveUntil.value : bailBondsmanActiveUntil.value;
    if (expiry == null) return 0;
    final diff = expiry.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  // ──────────────────────── ACTION 4: BROWSE PROVIDER DIRECTORY ─────────────

  Future<void> openProviderMarketplaceSheet({required bool forAttorney}) async {
    final role = forAttorney ? 'ATTORNEY' : 'BAIL_BONDSMAN';
    final roleTitle = forAttorney ? 'Preferred Attorney' : 'Preferred Bail Bondsman';
    directorySearchController.clear();

    isLoadingDirectory.value = true;
    _fetchDirectoryProviders(role);

    Get.bottomSheet(
      Container(
        height: 640.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select $roleTitle',
                        style: GoogleFonts.outfit(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Browse verified providers, pricing & bios',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: TextField(
                controller: directorySearchController,
                onChanged: filterDirectory,
                decoration: InputDecoration(
                  hintText: 'Search by name, law firm, or agency...',
                  hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // List of Providers
            Expanded(
              child: Obx(() {
                if (isLoadingDirectory.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1550A6)),
                  );
                }

                if (filteredProviders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            forAttorney ? Icons.gavel_rounded : Icons.account_balance_rounded,
                            size: 48.sp,
                            color: const Color(0xFFCBD5E1),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No verified providers available yet',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Providers must link their Stripe payout account to appear in the directory.',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: filteredProviders.length,
                  separatorBuilder: (_, _) => SizedBox(height: 14.h),
                  itemBuilder: (ctx, idx) {
                    final provider = filteredProviders[idx];
                    return _buildMarketplaceCard(ctx, provider, forAttorney: forAttorney);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _fetchDirectoryProviders(String role) async {
    try {
      final list = await providerPaymentRepo.getProviderDirectory(role: role);
      directoryProviders.assignAll(list);
      filteredProviders.assignAll(list);
    } catch (e) {
      debugPrint('Error fetching provider directory: $e');
    } finally {
      isLoadingDirectory.value = false;
    }
  }

  void filterDirectory(String query) {
    if (query.trim().isEmpty) {
      filteredProviders.assignAll(directoryProviders);
      return;
    }
    final q = query.toLowerCase();
    filteredProviders.assignAll(directoryProviders.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.company.toLowerCase().contains(q) ||
          p.specialization.toLowerCase().contains(q);
    }).toList());
  }

  Widget _buildMarketplaceCard(
    BuildContext context,
    ProviderDirectoryItem provider, {
    required bool forAttorney,
  }) {
    final avatar = provider.image;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26.r,
                backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.1),
                backgroundImage: (avatar.isNotEmpty)
                    ? NetworkImage(ApiConstants.getFileUrl(avatar))
                    : null,
                child: (avatar.isEmpty)
                    ? Text(
                        provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1550A6),
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.name,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF2563EB),
                          size: 16,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      provider.company,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 4.w),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '(${provider.reviewsCount} reviews)',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Short Bio / Description to attract user
          if (provider.shortDescription.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '"${provider.shortDescription}"',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF475569),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],

          SizedBox(height: 14.h),

          // Pricing Badges & Retain Action
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '\$${provider.monthlyServiceFee.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1550A6),
                          ),
                        ),
                        Text(
                          '/mo retainer',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${provider.serviceFee.toStringAsFixed(0)}/encounter',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1550A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
                onPressed: () {
                  Get.back(); // close marketplace sheet
                  openActivationConfirmModal(context, provider, forAttorney: forAttorney);
                },
                child: Text(
                  'Select as Preferred',
                  style: GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────── ACTION 5: ACTIVATION & STRIPE CHECKOUT ───────────

  void openActivationConfirmModal(
    BuildContext context,
    ProviderDirectoryItem provider, {
    required bool forAttorney,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF1550A6),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activate Preferred Coverage',
                          style: GoogleFonts.outfit(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          forAttorney ? 'Legal Defense Protection' : '24/7 Bail Bond Release',
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

              SizedBox(height: 18.h),

              // Provider Summary Box
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: const Color(0xFF1550A6).withValues(alpha: 0.1),
                      child: Text(
                        provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1550A6),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: GoogleFonts.inter(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            provider.company,
                            style: GoogleFonts.inter(
                              fontSize: 11.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Fee Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '30-Day Retainer Fee:',
                    style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF475569)),
                  ),
                  Text(
                    '\$${provider.monthlyServiceFee.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1550A6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Per-Encounter Rate:',
                    style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    '\$${provider.serviceFee.toStringAsFixed(2)} / call',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14.h),

              Text(
                'To activate ${provider.name} as your preferred provider, complete payment for your monthly retainer via Stripe. Your coverage will be active immediately.',
                style: GoogleFonts.inter(
                  fontSize: 11.5.sp,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              SizedBox(height: 20.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF635BFF), // Stripe purple
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () {
                        Get.back();
                        startStripeCheckout(context, provider, forAttorney: forAttorney);
                      },
                      icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'Activate & Pay',
                        style: GoogleFonts.inter(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

  Future<void> startStripeCheckout(
    BuildContext context,
    ProviderDirectoryItem provider, {
    required bool forAttorney,
  }) async {
    isProcessingCheckout.value = true;
    try {
      final session = await providerPaymentRepo.createCheckoutSession(provider.id);
      if (session == null || session['checkoutUrl'] == null) {
        Helpers.showError('Could not create payment session. Please try again.');
        return;
      }

      final checkoutUrl = session['checkoutUrl'].toString();
      final expectedSessionId = session['sessionId']?.toString() ?? '';

      if (context.mounted) {
        await StripeWebviewModal.show(
          context: context,
          initialUrl: checkoutUrl,
          title: 'Activate Preferred Provider',
          onPaymentSuccess: (sessionId) async {
            final targetSessionId = sessionId.isNotEmpty ? sessionId : expectedSessionId;
            await _completePaymentVerification(targetSessionId, provider, forAttorney: forAttorney);
          },
          onPaymentCancel: () {
            Helpers.showError('Payment cancelled. Provider was not activated.');
          },
        );
      }
    } catch (e) {
      Helpers.showError('Payment error: $e');
    } finally {
      isProcessingCheckout.value = false;
    }
  }

  Future<void> _completePaymentVerification(
    String sessionId,
    ProviderDirectoryItem provider, {
    required bool forAttorney,
  }) async {
    try {
      final res = await providerPaymentRepo.verifySession(sessionId);
      if (res != null && res['isPaid'] == true) {
        await _authService.getProfile();
        _loadInitialData();

        final profile = {
          'id': provider.id,
          'name': provider.name,
          'image': provider.image,
          'role': provider.role,
          'company': provider.company,
          'serviceFee': provider.serviceFee,
          'monthlyServiceFee': provider.monthlyServiceFee,
          'connected': true,
        };

        if (forAttorney) {
          attorneyProfile.value = profile;
          attorneyController.text = provider.name;
        } else {
          bailBondsmanProfile.value = profile;
          bailBondsmanController.text = provider.name;
        }

        Helpers.showSuccess(
          '${provider.name} is now your active Preferred Provider for 30 days!',
          title: 'Coverage Activated! 🎉',
        );
      } else {
        Helpers.showError('Payment verification pending. Please check back shortly.');
      }
    } catch (e) {
      debugPrint('Error verifying session: $e');
    }
  }

  @override
  void onClose() {
    attorneyController.dispose();
    bailBondsmanController.dispose();
    directorySearchController.dispose();
    super.onClose();
  }
}
