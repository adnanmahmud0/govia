class PreferenceCardDetailsResponse {
  final bool success;
  final String message;
  final PreferenceCardDetailsModel data;

  PreferenceCardDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PreferenceCardDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PreferenceCardDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: PreferenceCardDetailsModel.fromJson(json['data']),
    );
  }
}

class PreferenceCardDetailsModel {
  final String id;
  final String createdBy;
  final String cardTitle;
  final Surgeon surgeon;
  final String medication;
  final List<NameItem> supplies;
  final List<NameItem> sutures;
  final String instruments;
  final String positioningEquipment;
  final String prepping;
  final String workflow;
  final String keyNotes;
  final List<String> photoLibrary;
  final int downloadCount;
  final bool published;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String visibility;
  final bool isDeleted;

  PreferenceCardDetailsModel({
    required this.id,
    required this.createdBy,
    required this.cardTitle,
    required this.surgeon,
    required this.medication,
    required this.supplies,
    required this.sutures,
    required this.instruments,
    required this.positioningEquipment,
    required this.prepping,
    required this.workflow,
    required this.keyNotes,
    required this.photoLibrary,
    required this.downloadCount,
    required this.published,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.visibility,
    required this.isDeleted,
  });

  factory PreferenceCardDetailsModel.fromJson(Map<String, dynamic> json) {
    return PreferenceCardDetailsModel(
      id: json['id'] ?? json['_id'] ?? '',
      createdBy: json['createdBy'] ?? '',
      cardTitle: json['cardTitle'] ?? '',
      surgeon: Surgeon.fromJson(json['surgeon'] ?? {}),
      medication: json['medication'] ?? '',
      supplies: (json['supplies'] as List? ?? [])
          .map((e) => NameItem.fromJson(e))
          .toList(),
      sutures: (json['sutures'] as List? ?? [])
          .map((e) => NameItem.fromJson(e))
          .toList(),
      instruments: json['instruments'] ?? '',
      positioningEquipment: json['positioningEquipment'] ?? '',
      prepping: json['prepping'] ?? '',
      workflow: json['workflow'] ?? '',
      keyNotes: json['keyNotes'] ?? '',
      photoLibrary: List<String>.from(json['photoLibrary'] ?? []),
      downloadCount: json['downloadCount'] ?? 0,
      published: json['published'] ?? false,
      verificationStatus: json['verificationStatus'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      visibility: json['visibility'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

class NameItem {
  final String name;
  final int quantity;

  NameItem({required this.name, required this.quantity});

  factory NameItem.fromJson(Map<String, dynamic> json) {
    return NameItem(name: json['name'] ?? '', quantity: json['quantity'] ?? 1);
  }
}

class Surgeon {
  final String fullName;
  final String handPreference;
  final String specialty;
  final String contactNumber;
  final String musicPreference;

  Surgeon({
    required this.fullName,
    required this.handPreference,
    required this.specialty,
    required this.contactNumber,
    required this.musicPreference,
  });

  factory Surgeon.fromJson(Map<String, dynamic> json) {
    return Surgeon(
      fullName: json['fullName'] ?? '',
      handPreference: json['handPreference'] ?? '',
      specialty: json['specialty'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      musicPreference: json['musicPreference'] ?? '',
    );
  }
}
