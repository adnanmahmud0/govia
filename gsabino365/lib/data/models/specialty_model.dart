class Specialty {
  final String id;
  final String name;
  final bool isActive;

  Specialty({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory Specialty.fromJson(Map<String, dynamic> json) {
    return Specialty(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
