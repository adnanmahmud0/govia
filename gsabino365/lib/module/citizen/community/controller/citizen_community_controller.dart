import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';

class CommunityResource {
  final String? id;
  final String name;
  final String fullName;
  final String type;
  final String websiteUrl;
  final String? phoneNumber;
  final String? email;
  final String? logo;

  CommunityResource({
    this.id,
    required this.name,
    required this.fullName,
    required this.type,
    required this.websiteUrl,
    this.phoneNumber,
    this.email,
    this.logo,
  });

  factory CommunityResource.fromJson(Map<String, dynamic> json) {
    final rawName = (json['shortName'] ?? json['name'] ?? '').toString();
    final rawFullName = (json['name'] ?? json['shortName'] ?? '').toString();
    final logoPath = json['logo']?.toString();

    String deducedType = 'default';
    final lower = rawFullName.toLowerCase();
    if (lower.contains('dana')) {
      deducedType = 'danabond';
    } else if (lower.contains('aclu') || lower.contains('civil liberties')) {
      deducedType = 'aclu';
    } else if (lower.contains('legal aid')) {
      deducedType = 'las';
    } else if (lower.contains('naacp')) {
      deducedType = 'naacp';
    } else if (lower.contains('southern poverty') || lower.contains('splc')) {
      deducedType = 'splc';
    } else if (lower.contains('equal justice') || lower.contains('eji')) {
      deducedType = 'eji';
    } else if (lower.contains('places') ||
        lower.contains('dreams') ||
        lower.contains('ppd')) {
      deducedType = 'ppd';
    } else if (lower.contains('black mental') || lower.contains('bmha')) {
      deducedType = 'bmha';
    } else if (lower.contains('felon')) {
      deducedType = 'faf';
    } else if (lower.contains('fbi') || lower.contains('fbl')) {
      deducedType = 'fbi';
    } else if (lower.contains('justice.gov') ||
        lower.contains('civil rights division')) {
      deducedType = 'doj';
    } else if (lower.contains('nacole') || lower.contains('civilian oversight')) {
      deducedType = 'nacole';
    } else if (lower.contains('governor') || lower.contains('ohio')) {
      deducedType = 'gov';
    }

    return CommunityResource(
      id: json['_id'] ?? json['id'],
      name: rawName.isNotEmpty ? rawName : rawFullName,
      fullName: rawFullName.isNotEmpty ? rawFullName : rawName,
      type: deducedType,
      websiteUrl: json['websiteUrl'] ?? json['url'] ?? '',
      phoneNumber: json['phone'] ?? json['phoneNumber'],
      email: json['email'],
      logo: logoPath,
    );
  }
}

class CitizenCommunityController extends GetxController {
  final RxList<CommunityResource> resources = <CommunityResource>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize immediately with rich preset resources
    resources.assignAll(_defaultResources);
    // Fetch latest community resources from backend
    fetchResources();
  }

  Future<void> fetchResources() async {
    isLoading.value = true;
    try {
      final apiClient = Get.find<ApiClient>();
      final response = await apiClient.getData(ApiConstants.communityResources);

      if (response.statusCode == 200 && response.data != null) {
        final dynamic rawData = response.data['data'] ?? response.data;
        if (rawData is List && rawData.isNotEmpty) {
          final List<CommunityResource> parsed = rawData
              .map((item) =>
                  CommunityResource.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          if (parsed.isNotEmpty) {
            resources.assignAll(parsed);
          }
        }
      }
    } catch (e) {
      Helpers.debug('Error fetching community resources from API: $e');
    } finally {
      isLoading.value = false;
    }
  }

  static final List<CommunityResource> _defaultResources = [
    CommunityResource(
      name: 'Dana Bond',
      fullName: 'Dana Bail Bonds and Insurance Services LLC',
      type: 'danabond',
      websiteUrl: 'https://DanaBond.com',
      phoneNumber: '2164108911',
      email: 'danaacyinsurance@gmail.com',
    ),
    CommunityResource(
      name: 'American Civil Li..',
      fullName: 'American Civil Liberties Union',
      type: 'aclu',
      websiteUrl: 'https://www.aclu.org',
    ),
    CommunityResource(
      name: 'Legal Aid Society',
      fullName: 'Legal Aid Society',
      type: 'las',
      websiteUrl: 'https://www.legalaidinfo.org',
    ),
    CommunityResource(
      name: 'NAACP',
      fullName: 'National Association for the Advancement of Colored People',
      type: 'naacp',
      websiteUrl: 'https://naacp.org',
    ),
    CommunityResource(
      name: 'Southern Povert..',
      fullName: 'Southern Poverty Law Center',
      type: 'splc',
      websiteUrl: 'https://www.splcenter.org',
    ),
    CommunityResource(
      name: 'Equal Justice Init..',
      fullName: 'Equal Justice Initiative',
      type: 'eji',
      websiteUrl: 'https://eji.org',
    ),
    CommunityResource(
      name: 'People, Places..',
      fullName: 'People, Places, and Dreams',
      type: 'ppd',
      websiteUrl: 'https://peopleplacesdreams.org',
    ),
    CommunityResource(
      name: 'Black Mental He..',
      fullName: 'Black Mental Health Alliance',
      type: 'bmha',
      websiteUrl: 'https://blackmentalhealth.com',
    ),
    CommunityResource(
      name: 'Friend a Felon',
      fullName: 'Friend a Felon',
      type: 'faf',
      websiteUrl: 'https://www.friendafelon.com',
    ),
    CommunityResource(
      name: 'FBL.Gov',
      fullName: 'Federal Bureau of Investigation / FBL',
      type: 'fbi',
      websiteUrl: 'https://www.fbi.gov',
    ),
    CommunityResource(
      name: 'Civil Rights Divis..',
      fullName: 'Department of Justice Civil Rights Division',
      type: 'doj',
      websiteUrl: 'https://www.justice.gov/crt',
    ),
    CommunityResource(
      name: 'Nacole. org',
      fullName: 'National Association for Civilian Oversight of Law Enforcement',
      type: 'nacole',
      websiteUrl: 'https://www.nacole.org',
    ),
    CommunityResource(
      name: 'Governor.Ohio',
      fullName: 'Office of the Governor of Ohio',
      type: 'ohio',
      websiteUrl: 'https://governor.ohio.gov',
    ),
    CommunityResource(
      name: 'Cuyahoga County',
      fullName: 'Cuyahoga County Government',
      type: 'cuyahoga',
      websiteUrl: 'https://cuyahogacounty.us',
    ),
    CommunityResource(
      name: 'The Marshall Pro.',
      fullName: 'The Marshall Project',
      type: 'marshall',
      websiteUrl: 'https://www.themarshallproject.org',
    ),
    CommunityResource(
      name: 'OHCHR',
      fullName: 'Office of the High Commissioner for Human Rights',
      type: 'ohchr',
      websiteUrl: 'https://www.ohchr.org',
    ),
    CommunityResource(
      name: 'Cleveland Munic..',
      fullName: 'Cleveland Municipal Court',
      type: 'cleveland',
      websiteUrl: 'https://clevelandmunicipalcourt.org',
    ),
    CommunityResource(
      name: 'The Daily',
      fullName: 'The Daily',
      type: 'daily',
      websiteUrl: 'https://thedaily.case.edu',
    ),
    CommunityResource(
      name: 'Giving Compass',
      fullName: 'Giving Compass',
      type: 'compass',
      websiteUrl: 'https://givingcompass.org',
    ),
    CommunityResource(
      name: 'The Bail Peoject',
      fullName: 'The Bail Project',
      type: 'bail',
      websiteUrl: 'https://bailproject.org',
    ),
    CommunityResource(
      name: 'Price Centerprises',
      fullName: 'Price Centerprises',
      type: 'price',
      websiteUrl: 'https://pricecenterprises.com',
    ),
    CommunityResource(
      name: 'Stand Together',
      fullName: 'Stand Together',
      type: 'stand',
      websiteUrl: 'https://standtogether.org',
    ),
    CommunityResource(
      name: 'Crime Stopper U..',
      fullName: 'Crime Stoppers USA',
      type: 'crimestoppers',
      websiteUrl: 'https://www.crimestoppersusa.org',
    ),
    CommunityResource(
      name: 'Glide',
      fullName: 'Glide Foundation',
      type: 'glide',
      websiteUrl: 'https://www.glide.org',
    ),
    CommunityResource(
      name: 'National Police',
      fullName: 'National Police Association',
      type: 'nationalpolice',
      websiteUrl: 'https://nationalpolice.org',
    ),
  ];

  void openResource(CommunityResource resource) {
    if (resource.phoneNumber != null || resource.email != null) {
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                resource.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (resource.email != null)
                Text(
                  resource.email!,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              
              // Website Action Button
              ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  _launch(resource.websiteUrl);
                },
                icon: const Icon(Icons.language_rounded, color: Colors.white),
                label: const Text('Visit Website', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1550A6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Phone Call Action Button
              if (resource.phoneNumber != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    _launch('tel:${resource.phoneNumber}');
                  },
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF1550A6)),
                  label: Text('Call ${resource.phoneNumber}', style: const TextStyle(color: Color(0xFF1550A6), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1550A6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Email Action Button
              if (resource.email != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    _launch('mailto:${resource.email}');
                  },
                  icon: const Icon(Icons.email_rounded, color: Color(0xFF1550A6)),
                  label: const Text('Send Email', style: TextStyle(color: Color(0xFF1550A6), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1550A6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Cancel Button
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    } else {
      Get.snackbar(
        resource.fullName,
        'Opening resource website at ${resource.websiteUrl}...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1550A6),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      _launch(resource.websiteUrl);
    }
  }

  Future<void> _launch(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (urlString.startsWith('tel:') || urlString.startsWith('mailto:')) {
        await launchUrl(url);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not launch $urlString',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
      );
    }
  }
}
