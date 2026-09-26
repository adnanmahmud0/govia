class ProviderDirectoryItem {
  final String id;
  final String name;
  final String role;
  final String image;
  final String company;
  final String licenseNumber;
  final String specialization;
  final String licensedStates;
  final double serviceFee;
  final double monthlyServiceFee;
  final String shortDescription;
  final bool isStripeVerified;
  final double rating;
  final int reviewsCount;

  ProviderDirectoryItem({
    required this.id,
    required this.name,
    required this.role,
    this.image = '',
    this.company = '',
    this.licenseNumber = '',
    this.specialization = '',
    this.licensedStates = '',
    this.serviceFee = 0.0,
    this.monthlyServiceFee = 0.0,
    this.shortDescription = '',
    this.isStripeVerified = false,
    this.rating = 5.0,
    this.reviewsCount = 0,
  });

  factory ProviderDirectoryItem.fromJson(Map<String, dynamic> json) {
    return ProviderDirectoryItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Provider',
      role: json['role']?.toString().toUpperCase() ?? 'ATTORNEY',
      image: json['image']?.toString() ?? json['profilePicture']?.toString() ?? '',
      company: json['company']?.toString() ??
          json['lawFirmName']?.toString() ??
          json['companyName']?.toString() ??
          'Independent Practice',
      licenseNumber: json['licenseNumber']?.toString() ??
          json['barAssociationNumber']?.toString() ??
          '',
      specialization: json['specialization']?.toString() ?? '',
      licensedStates: json['licensedStates']?.toString() ??
          json['licensedStatesToPractice']?.toString() ??
          'Nationwide',
      serviceFee: (json['serviceFee'] is num)
          ? (json['serviceFee'] as num).toDouble()
          : double.tryParse(json['serviceFee']?.toString() ?? '0') ?? 0.0,
      monthlyServiceFee: (json['monthlyServiceFee'] is num)
          ? (json['monthlyServiceFee'] as num).toDouble()
          : double.tryParse(json['monthlyServiceFee']?.toString() ?? '0') ?? 0.0,
      shortDescription: json['shortDescription']?.toString() ?? '',
      isStripeVerified: json['isStripeVerified'] == true ||
          json['payoutsEnabled'] == true,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      reviewsCount: (json['reviewsCount'] is num)
          ? (json['reviewsCount'] as num).toInt()
          : int.tryParse(json['reviewsCount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'image': image,
      'company': company,
      'licenseNumber': licenseNumber,
      'specialization': specialization,
      'licensedStates': licensedStates,
      'serviceFee': serviceFee,
      'monthlyServiceFee': monthlyServiceFee,
      'shortDescription': shortDescription,
      'isStripeVerified': isStripeVerified,
      'rating': rating,
      'reviewsCount': reviewsCount,
    };
  }
}
