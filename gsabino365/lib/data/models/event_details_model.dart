class EventDetailsResponse {
  final bool success;
  final String message;
  final EventDetailsModel data;

  EventDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory EventDetailsResponse.fromJson(Map<String, dynamic> json) {
    return EventDetailsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: EventDetailsModel.fromJson(json['data']),
    );
  }
}

class PreferenceCardModel {
  final String id;
  final String cardTitle;

  PreferenceCardModel({required this.id, required this.cardTitle});

  factory PreferenceCardModel.fromJson(Map<String, dynamic> json) {
    return PreferenceCardModel(
      id: json['id'] ?? json['_id'] ?? '',
      cardTitle: json['cardTitle'] ?? json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {"_id": id, "cardTitle": cardTitle};
  }
}

class EventDetailsModel {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final String time;
  final int durationHours;
  final String eventType;
  final String location;
  final PreferenceCardModel? preferenceCard;
  final String? notes;
  final PersonnelModel? personnel;
  final String? tag;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventDetailsModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.time,
    required this.durationHours,
    required this.eventType,
    required this.location,
    this.preferenceCard,
    this.notes,
    this.personnel,
    this.tag,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventDetailsModel.fromJson(Map<String, dynamic> json) {
    return EventDetailsModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      durationHours: json['durationInHours'] ?? json['durationHours'] ?? 0,
      eventType: json['eventType'] ?? '',
      location: json['location'] ?? '',
      preferenceCard: (json['linkedPreferenceCard'] != null && 
                       json['linkedPreferenceCard'] is Map && 
                       (json['linkedPreferenceCard'] as Map).isNotEmpty)
          ? PreferenceCardModel.fromJson(json['linkedPreferenceCard'])
          : (json['preferenceCard'] != null && 
             json['preferenceCard'] is Map && 
             (json['preferenceCard'] as Map).isNotEmpty)
          ? PreferenceCardModel.fromJson(json['preferenceCard'])
          : null,
      notes: json['keyNotes'] ?? json['notes'],
      personnel: json['personnel'] != null
          ? PersonnelModel.fromJson(json['personnel'])
          : null,
      tag: json['tag'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "title": title,
      "date": date.toIso8601String(),
      "time": time,
      "durationInHours": durationHours,
      "eventType": eventType,
      "location": location,
      "preferenceCard": preferenceCard?.toJson(),
      "keyNotes": notes,
      "personnel": personnel?.toJson(),
      "tag": tag,
      "createdBy": createdBy,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }
}

class PersonnelModel {
  final String leadSurgeon;
  final List<String> surgicalTeam;

  PersonnelModel({required this.leadSurgeon, required this.surgicalTeam});

  factory PersonnelModel.fromJson(Map<String, dynamic> json) {
    return PersonnelModel(
      leadSurgeon: json['leadSurgeon'] ?? '',
      surgicalTeam: List<String>.from(
        json['surgicalTeamMembers'] ?? json['surgicalTeam'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {"leadSurgeon": leadSurgeon, "surgicalTeam": surgicalTeam};
  }
}
