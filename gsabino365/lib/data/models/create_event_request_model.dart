class CreateEventRequestModel {
  final String title;
  final String date; // yyyy-MM-dd
  final String time;
  final int durationInHours;
  final String eventType;
  final String location;
  final String keyNotes;
  final PersonnelRequestModel personnel;
  final String? preferenceCard;

  CreateEventRequestModel({
    required this.title,
    required this.date,
    required this.time,
    required this.durationInHours,
    required this.eventType,
    required this.location,
    required this.keyNotes,
    required this.personnel,
    this.preferenceCard,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "title": title,
      "date": date,
      "time": time,
      "durationInHours": durationInHours,
      "eventType": eventType,
      "location": location,
      "keyNotes": keyNotes,
      "personnel": personnel.toJson(),
    };
    if (preferenceCard != null && preferenceCard!.isNotEmpty) {
      data["preferenceCard"] = preferenceCard;
    }
    return data;
  }
}

class PersonnelRequestModel {
  final String leadSurgeon;
  final List<String> surgicalTeamMembers;

  PersonnelRequestModel({
    required this.leadSurgeon,
    required this.surgicalTeamMembers,
  });

  Map<String, dynamic> toJson() {
    return {
      "leadSurgeon": leadSurgeon,
      "surgicalTeamMembers": surgicalTeamMembers
    };
  }
}
