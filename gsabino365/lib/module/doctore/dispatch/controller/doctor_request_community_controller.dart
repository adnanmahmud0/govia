import 'package:get/get.dart';

class DoctorRequestCommunityController extends GetxController {
  final RxString activeCategory = 'All'.obs; // 'All', 'Shelter', 'Food', 'Clothing', 'Church'
  final RxString searchQuery = ''.obs;
  
  // Selected resource pin to show details card at bottom
  final Rxn<Map<String, dynamic>> selectedResource = Rxn<Map<String, dynamic>>();

  final List<String> categories = ['All', 'Shelter', 'Food', 'Clothing', 'Church'];

  // Mock community resources list
  final List<Map<String, dynamic>> allResources = [
    {
      'id': '1',
      'name': 'Hope Haven Emergency Shelter',
      'category': 'Shelter',
      'address': '724 Broadway Ave, Cleveland, OH',
      'phone': '(216) 555-0143',
      'distance': '0.8 miles',
      'dx': 0.35, // fractional x on map
      'dy': 0.42, // fractional y on map
      'details': 'Provides overnight shelter, warm showers, and casework services for individuals and families.',
      'hours': 'Open 24/7',
    },
    {
      'id': '2',
      'name': 'Downtown Community Kitchen',
      'category': 'Food',
      'address': '1042 Superior Ave, Cleveland, OH',
      'phone': '(216) 555-0188',
      'distance': '1.2 miles',
      'dx': 0.65,
      'dy': 0.30,
      'details': 'Serving free hot breakfast (7-9 AM) and dinner (5-7 PM) daily to anyone in need.',
      'hours': 'Daily: 7 AM - 7 PM',
    },
    {
      'id': '3',
      'name': 'St. Jude Clothing & Food Bank',
      'category': 'Clothing',
      'address': '1890 W 25th St, Cleveland, OH',
      'phone': '(216) 555-0211',
      'distance': '1.5 miles',
      'dx': 0.22,
      'dy': 0.68,
      'details': 'Offers free seasonal clothing, winter coats, shoes, and non-perishable pantry packages.',
      'hours': 'Mon-Fri: 9 AM - 4 PM',
    },
    {
      'id': '4',
      'name': 'Trinity Methodist Grace Church',
      'category': 'Church',
      'address': '3000 Euclid Ave, Cleveland, OH',
      'phone': '(216) 555-0300',
      'distance': '2.1 miles',
      'dx': 0.78,
      'dy': 0.62,
      'details': 'Faith-based support offering community counseling, support groups, and emergency assistance funds.',
      'hours': 'Sun: 8 AM - 4 PM, Wed: 9 AM - 6 PM',
    },
    {
      'id': '5',
      'name': 'Salvation Army Harbor Light',
      'category': 'Shelter',
      'address': '1710 Prospect Ave, Cleveland, OH',
      'phone': '(216) 555-0250',
      'distance': '0.5 miles',
      'dx': 0.50,
      'dy': 0.55,
      'details': 'Comprehensive shelter, transitional housing, rehab program, and community meals.',
      'hours': 'Open 24/7',
    },
    {
      'id': '6',
      'name': 'Grace Food Pantry',
      'category': 'Food',
      'address': '4512 Payne Ave, Cleveland, OH',
      'phone': '(216) 555-0289',
      'distance': '1.9 miles',
      'dx': 0.82,
      'dy': 0.20,
      'details': 'Providing groceries, fresh produce, and baby formula to local residents.',
      'hours': 'Tue & Thu: 10 AM - 2 PM',
    },
  ];

  // Filtered resources list depending on active category and search query
  List<Map<String, dynamic>> get filteredResources {
    return allResources.where((res) {
      final matchesCategory = activeCategory.value == 'All' || res['category'] == activeCategory.value;
      final matchesSearch = searchQuery.value.isEmpty ||
          res['name'].toString().toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          res['address'].toString().toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void selectCategory(String category) {
    activeCategory.value = category;
    // Unselect selected resource when category changes to avoid confusion if it becomes filtered out
    if (selectedResource.value != null && 
        category != 'All' && 
        selectedResource.value!['category'] != category) {
      selectedResource.value = null;
    }
  }

  void selectResourcePin(Map<String, dynamic> resource) {
    selectedResource.value = resource;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
