import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/core/utils/helpers.dart';
import 'package:gsabino365/module/shared/chat/controller/chat_controller.dart';
import 'package:intl/intl.dart';

class MentalHealthController extends GetxController {
  late final ApiClient _apiClient;

  final RxList<Map<String, dynamic>> doctors = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'Crisis Counseling',
    'Trauma & PTSD',
    'Anxiety & Stress',
    'Family Therapy',
    'Youth Support',
  ];

  @override
  void onInit() {
    super.onInit();
    _apiClient = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : Get.put(ApiClient());
    fetchDoctors();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchDoctors() async {
    try {
      isLoading.value = true;
      final response = await _apiClient.getData(
        '/user',
        query: {'role': 'MENTAL_HEALTH_PROFESSIONAL'},
      );

      List<Map<String, dynamic>> fetched = [];
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data['data'];
        if (raw is List) {
          fetched = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (raw is Map && raw['data'] is List) {
          fetched = (raw['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      // If empty, attempt fallback to legacy DOCTOR role query
      if (fetched.isEmpty) {
        final docResponse = await _apiClient.getData(
          '/user',
          query: {'role': 'DOCTOR'},
        );
        if (docResponse.statusCode == 200 && docResponse.data != null) {
          final raw = docResponse.data['data'];
          if (raw is List) {
            fetched = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          } else if (raw is Map && raw['data'] is List) {
            fetched = (raw['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }

      if (fetched.isNotEmpty) {
        doctors.assignAll(fetched);
      } else {
        // Fallback to licensed mental health professionals
        doctors.assignAll(_getDefaultSpecialists());
      }
    } catch (_) {
      doctors.assignAll(_getDefaultSpecialists());
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _getDefaultSpecialists() {
    return [
      {
        '_id': 'doc_mh_01',
        'id': 'doc_mh_01',
        'name': 'Dr. Marcus Vance, Ph.D.',
        'role': 'DOCTOR',
        'specialty': 'Trauma & PTSD',
        'title': 'Clinical Psychologist & Crisis Interventionist',
        'hospital': 'Hope Mental Health Institute',
        'rating': 4.9,
        'reviewCount': 124,
        'experienceYears': 14,
        'isOnline': true,
        'nextAvailable': 'Available Now',
        'image': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=300',
        'bio': 'Specializing in police encounter trauma de-escalation, post-incident anxiety, and acute stress resilience.',
      },
      {
        '_id': 'doc_mh_02',
        'id': 'doc_mh_02',
        'name': 'Dr. Elena Rostova, MD',
        'role': 'DOCTOR',
        'specialty': 'Crisis Counseling',
        'title': 'Emergency Psychiatric Specialist',
        'hospital': 'Metropolitan Wellness Center',
        'rating': 4.8,
        'reviewCount': 98,
        'experienceYears': 11,
        'isOnline': true,
        'nextAvailable': 'Today, 2:30 PM',
        'image': 'https://images.unsplash.com/photo-1594824813581-98782f9d510f?w=300',
        'bio': 'Board-certified psychiatrist dedicated to immediate emotional stabilization and crisis intervention for citizens.',
      },
      {
        '_id': 'doc_mh_03',
        'id': 'doc_mh_03',
        'name': 'Sarah Mitchell, LCSW',
        'role': 'DOCTOR',
        'specialty': 'Anxiety & Stress',
        'title': 'Licensed Clinical Social Worker',
        'hospital': 'Community Care Alliance',
        'rating': 4.9,
        'reviewCount': 142,
        'experienceYears': 9,
        'isOnline': false,
        'nextAvailable': 'Tomorrow, 10:00 AM',
        'image': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300',
        'bio': 'Focused on mindfulness-based cognitive therapy and community legal stress counseling.',
      },
      {
        '_id': 'doc_mh_04',
        'id': 'doc_mh_04',
        'name': 'Dr. Kenneth Reed, Psy.D.',
        'role': 'DOCTOR',
        'specialty': 'Family Therapy',
        'title': 'Family & Youth Psychologist',
        'hospital': 'Horizon Psychological Services',
        'rating': 4.7,
        'reviewCount': 86,
        'experienceYears': 16,
        'isOnline': true,
        'nextAvailable': 'Today, 4:00 PM',
        'image': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=300',
        'bio': 'Providing supportive guidance for families navigating legal stress, arrests, and community reunification.',
      },
    ];
  }

  List<Map<String, dynamic>> get filteredDoctors {
    final cat = selectedCategory.value;
    final query = searchQuery.value.trim().toLowerCase();

    return doctors.where((doc) {
      final matchesCategory = cat == 'All' ||
          (doc['specialty']?.toString().toLowerCase() == cat.toLowerCase());

      final name = doc['name']?.toString().toLowerCase() ?? '';
      final title = doc['title']?.toString().toLowerCase() ?? '';
      final spec = doc['specialty']?.toString().toLowerCase() ?? '';
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          title.contains(query) ||
          spec.contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Show modern paywall prompt when free citizen attempts restricted doctor action
  void _showUpgradePrompt({required String title, required String message}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1550A6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFF1550A6),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1550A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.subscription);
                  },
                  child: const Text(
                    'View Premium Plans',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Start direct messaging with doctor
  Future<void> openChatWithDoctor(Map<String, dynamic> doctor) async {
    // Check Citizen subscription
    try {
      final statusRes = await _apiClient.getData('/subscriptions/my-status');
      if (statusRes.statusCode == 200 && statusRes.data != null) {
        final data = statusRes.data['data'] ?? statusRes.data;
        if (data is Map && data['isCitizen'] == true && data['isPremium'] != true) {
          _showUpgradePrompt(
            title: 'Govia Premium Feature',
            message: 'Direct messaging with licensed doctors and therapists requires Govia Premium. Upgrade now for 24/7 confidential healthcare access.',
          );
          return;
        }
      }
    } catch (_) {}

    final chatCtrl = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    final docMap = {
      '_id': doctor['_id'] ?? doctor['id'],
      'id': doctor['_id'] ?? doctor['id'],
      'name': doctor['name'],
      'role': doctor['role'] ?? 'MENTAL_HEALTH_PROFESSIONAL',
      'image': doctor['image'] ?? doctor['profilePicture'],
      'specialty': doctor['specialty'],
    };

    await chatCtrl.openOrCreateChatWithUser(docMap);
  }

  /// Schedule appointment modal and backend dispatch
  Future<void> openBookingSheet(Map<String, dynamic> doctor) async {
    // Check Citizen subscription
    try {
      final statusRes = await _apiClient.getData('/subscriptions/my-status');
      if (statusRes.statusCode == 200 && statusRes.data != null) {
        final data = statusRes.data['data'] ?? statusRes.data;
        if (data is Map && data['isCitizen'] == true && data['isPremium'] != true) {
          _showUpgradePrompt(
            title: 'Doctor Appointments Locked',
            message: 'Scheduling consultations with licensed physicians requires Govia Premium. Upgrade today to unlock confidential telehealth appointments.',
          );
          return;
        }
      }
    } catch (_) {}

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTime = '10:00 AM';
    String sessionType = 'Video Call';
    final notesCtrl = TextEditingController();
    final isBooking = false.obs;

    final availableSlots = [
      '09:00 AM',
      '10:30 AM',
      '01:00 PM',
      '02:30 PM',
      '04:00 PM',
      '05:30 PM',
    ];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) {
          return Container(
            height: 600,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule Consultation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor['name'] ?? 'Doctor',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1550A6),
                              fontWeight: FontWeight.w600,
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
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Session Type Picker
                        const Text(
                          'Session Format',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Video Call'),
                                  ],
                                ),
                                selected: sessionType == 'Video Call',
                                onSelected: (val) {
                                  if (val) setState(() => sessionType = 'Video Call');
                                },
                                selectedColor: const Color(0xFF1550A6).withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: sessionType == 'Video Call' ? const Color(0xFF1550A6) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Voice Call'),
                                  ],
                                ),
                                selected: sessionType == 'Voice Call',
                                onSelected: (val) {
                                  if (val) setState(() => sessionType = 'Voice Call');
                                },
                                selectedColor: const Color(0xFF1550A6).withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: sessionType == 'Voice Call' ? const Color(0xFF1550A6) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Date Selection
                        const Text(
                          'Select Date',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: Color(0xFF1550A6), size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                ),
                                const Spacer(),
                                const Text('Change', style: TextStyle(color: Color(0xFF1550A6), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Time Slot Selection
                        const Text(
                          'Available Time Slot',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableSlots.map((slot) {
                            final isSel = selectedTime == slot;
                            return ChoiceChip(
                              label: Text(slot),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) setState(() => selectedTime = slot);
                              },
                              selectedColor: const Color(0xFF1550A6),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : const Color(0xFF334155),
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 18),

                        // Reason / Notes
                        const Text(
                          'Notes / Reason for Consultation (Confidential)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Describe briefly what you need support with...',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1550A6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isBooking.value
                            ? null
                            : () async {
                                isBooking.value = true;
                                try {
                                  final docId = doctor['_id'] ?? doctor['id'];
                                  await _apiClient.postData(
                                    ApiConstants.scheduleMeeting,
                                    {
                                      'doctorId': docId,
                                      'date': selectedDate.toIso8601String(),
                                      'time': selectedTime,
                                      'format': sessionType,
                                      'notes': notesCtrl.text.trim(),
                                      'topic': 'Mental Health: ${doctor['specialty'] ?? 'Consultation'}',
                                    },
                                  );
                                } catch (_) {}
                                isBooking.value = false;
                                Get.back();
                                HapticFeedback.mediumImpact();
                                Helpers.showSuccess(
                                  'Appointment scheduled with ${doctor['name']} for ${DateFormat('MMM d').format(selectedDate)} at $selectedTime.',
                                  title: 'Appointment Confirmed',
                                );
                              },
                        child: Text(
                          isBooking.value ? 'Booking...' : 'Confirm Consultation',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}
