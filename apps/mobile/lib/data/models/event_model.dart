class EventsResponse {
  final bool success;
  final String message;
  final List<EventModel> data;

  EventsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory EventsResponse.fromJson(Map<String, dynamic> json) {
    return EventsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => EventModel.fromJson(e))
          .toList(),
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final int durationHours;
  final String eventType;
  final String location;
  final String? notes; // optional

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.durationHours,
    required this.eventType,
    required this.location,
    this.notes,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      durationHours: json['durationInHours'] ?? json['durationHours'] ?? 0,
      eventType: json['eventType'] ?? '',
      location: json['location'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "title": title,
      "date": date.toIso8601String(),
      "time": time,
      "durationHours": durationHours,
      "eventType": eventType,
      "location": location,
      "notes": notes,
    };
  }
}
