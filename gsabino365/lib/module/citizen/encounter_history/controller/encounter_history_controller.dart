import 'package:get/get.dart';

class EncounterModel {
  final String id;
  final String title;
  final String dateTime;
  final String locationName;
  final String duration;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String description;

  EncounterModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.locationName,
    required this.duration,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

class EncounterHistoryController extends GetxController {
  final RxString activeFilter = 'All'.obs;

  final List<EncounterModel> allEncounters = [
    EncounterModel(
      id: '1',
      title: 'Evening Incident',
      dateTime: 'April 28, 2026 • 8:45 PM',
      locationName: 'Main Parking Lot',
      duration: '3:42',
      imageUrl: 'https://images.unsplash.com/photo-1542282088-fe8426682b8f?w=600&auto=format&fit=crop&q=60',
      latitude: 40.7128,
      longitude: -74.0060,
      description: 'Dashcam footage captured near the central aisle of the Main Parking Lot. Vehicle collision observed and logged for insurance verification.',
    ),
    EncounterModel(
      id: '2',
      title: 'Traffic Stop Inquiry',
      dateTime: 'April 15, 2026 • 2:15 PM',
      locationName: 'Broadway Avenue',
      duration: '5:10',
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600&auto=format&fit=crop&q=60',
      latitude: 40.7589,
      longitude: -73.9851,
      description: 'Routine traffic check interaction. Audio and video logs stored for safety compliance.',
    ),
  ];

  final RxList<EncounterModel> filteredEncounters = <EncounterModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    applyFilter('All');
  }

  void applyFilter(String filter) {
    activeFilter.value = filter;
    if (filter == 'All') {
      filteredEncounters.value = allEncounters;
    } else if (filter == 'This Month') {
      // Filter for April 2026
      filteredEncounters.value = allEncounters.where((e) => e.dateTime.contains('April')).toList();
    } else {
      // Filter for 2026
      filteredEncounters.value = allEncounters.where((e) => e.dateTime.contains('2026')).toList();
    }
  }
}
