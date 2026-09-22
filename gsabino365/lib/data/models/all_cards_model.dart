class AllCardsResponse {
  final bool success;
  final String message;
  final List<PreferenceCard> data;

  AllCardsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AllCardsResponse.fromJson(Map<String, dynamic> json) {
    return AllCardsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? List<PreferenceCard>.from(
              json['data'].map((x) => PreferenceCard.fromJson(x)),
            )
          : [],
    );
  }
}
class PreferenceCard {
  final String id;
  final String createdBy;
  final String cardTitle;
  final Surgeon surgeon;
  final String medication;
  final List<dynamic> supplies;
  final List<dynamic> sutures;
  final String instruments;
  final String positioningEquipment;
  final String prepping;
  final String workflow;
  final String keyNotes;
  final List<dynamic> photoLibrary;
  final int downloadCount;
  final bool published;
  final String verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreferenceCard({
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
  });

  factory PreferenceCard.fromJson(Map<String, dynamic> json) {
    return PreferenceCard(
      id: json['_id'] ?? '',
      createdBy: json['createdBy'] ?? '',
      cardTitle: json['cardTitle'] ?? '',
      surgeon: Surgeon.fromJson(json['surgeon'] ?? {}),
      medication: json['medication'] ?? '',
      supplies: json['supplies'] ?? [],
      sutures: json['sutures'] ?? [],
      instruments: json['instruments'] ?? '',
      positioningEquipment: json['positioningEquipment'] ?? '',
      prepping: json['prepping'] ?? '',
      workflow: json['workflow'] ?? '',
      keyNotes: json['keyNotes'] ?? '',
      photoLibrary: json['photoLibrary'] ?? [],
      downloadCount: json['downloadCount'] ?? 0,
      published: json['published'] ?? false,
      verificationStatus: json['verificationStatus'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
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
