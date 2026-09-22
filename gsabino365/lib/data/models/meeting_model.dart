class MeetingRecording {
  final String? id;
  final String? fileType;
  final String? fileExtension;
  final int? fileSize;
  final String? playUrl;
  final String? downloadUrl;
  final String? recordingType;
  final DateTime? recordingStart;
  final DateTime? recordingEnd;

  MeetingRecording({
    this.id,
    this.fileType,
    this.fileExtension,
    this.fileSize,
    this.playUrl,
    this.downloadUrl,
    this.recordingType,
    this.recordingStart,
    this.recordingEnd,
  });

  factory MeetingRecording.fromJson(Map<String, dynamic> json) {
    return MeetingRecording(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      fileType: json['fileType']?.toString(),
      fileExtension: json['fileExtension']?.toString(),
      fileSize: json['fileSize'] != null
          ? int.tryParse(json['fileSize'].toString())
          : null,
      playUrl: json['playUrl']?.toString(),
      downloadUrl: json['downloadUrl']?.toString(),
      recordingType: json['recordingType']?.toString(),
      recordingStart: json['recordingStart'] != null
          ? DateTime.tryParse(json['recordingStart'].toString())
          : null,
      recordingEnd: json['recordingEnd'] != null
          ? DateTime.tryParse(json['recordingEnd'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (fileType != null) 'fileType': fileType,
      if (fileExtension != null) 'fileExtension': fileExtension,
      if (fileSize != null) 'fileSize': fileSize,
      if (playUrl != null) 'playUrl': playUrl,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (recordingType != null) 'recordingType': recordingType,
      if (recordingStart != null)
        'recordingStart': recordingStart?.toIso8601String(),
      if (recordingEnd != null) 'recordingEnd': recordingEnd?.toIso8601String(),
    };
  }
}

class MeetingModel {
  final String id; // MongoDB _id
  final String roomName;
  final String? zoomMeetingId;
  final String topic;
  final String? joinUrl;
  final String? startUrl;
  final String? password;
  final String status;
  final String meetingType;
  final String? recordingUrl;
  final String? sessionName;
  final String? token;
  final String? livekitUrl;

  final String? callerName;
  final String? callerPhone;
  final String? callerAvatar;
  final String? userId;
  final String? hostId;
  final String? category;
  final DateTime? createdAt;

  // Backend IMeeting alignment fields
  final DateTime? startTime;
  final int? durationMinutes;
  final String? timezone;
  final String? agenda;
  final DateTime? endedAt;
  final List<MeetingRecording> recordings;
  final List<String> joinedAttorneys;
  final List<String> joinedParticipants;
  final String? vaultFolderId;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

  MeetingModel({
    required this.id,
    required this.roomName,
    this.zoomMeetingId,
    required this.topic,
    this.joinUrl,
    this.startUrl,
    this.password,
    required this.status,
    required this.meetingType,
    this.recordingUrl,
    this.sessionName,
    this.token,
    this.livekitUrl,
    this.callerName,
    this.callerPhone,
    this.callerAvatar,
    this.userId,
    this.hostId,
    this.category,
    this.createdAt,
    this.startTime,
    this.durationMinutes,
    this.timezone,
    this.agenda,
    this.endedAt,
    this.recordings = const [],
    this.joinedAttorneys = const [],
    this.joinedParticipants = const [],
    this.vaultFolderId,
    this.latitude,
    this.longitude,
    this.locationAddress,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    final rName = json['roomName']?.toString() ??
        json['sessionName']?.toString() ??
        (json['zoomMeetingId'] != null
            ? 'govia_${json['zoomMeetingId']}'
            : 'govia_${json['_id']}');

    String? caller;
    String? phone;
    String? avatar;
    String? uId;

    if (json['userId'] is Map<String, dynamic>) {
      final uMap = json['userId'] as Map<String, dynamic>;
      caller = uMap['name']?.toString();
      phone = uMap['phoneNumber']?.toString();
      avatar = uMap['profilePicture']?.toString() ?? uMap['image']?.toString();
      uId = uMap['_id']?.toString() ?? uMap['id']?.toString();
    } else if (json['userId'] != null) {
      uId = json['userId'].toString();
    }

    if (json['callerName'] != null) {
      caller = json['callerName']?.toString();
    }
    if (json['callerId'] is Map<String, dynamic>) {
      final cMap = json['callerId'] as Map<String, dynamic>;
      caller ??= cMap['name']?.toString();
      avatar ??=
          cMap['profilePicture']?.toString() ?? cMap['image']?.toString();
      uId ??= cMap['_id']?.toString() ?? cMap['id']?.toString();
    } else if (json['callerId'] != null) {
      uId ??= json['callerId'].toString();
    }

    String? hId;
    if (json['hostId'] is Map<String, dynamic>) {
      hId = json['hostId']['_id']?.toString() ??
          json['hostId']['id']?.toString();
    } else if (json['hostId'] != null) {
      hId = json['hostId'].toString();
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }

    DateTime? startTime;
    if (json['startTime'] != null) {
      startTime = DateTime.tryParse(json['startTime'].toString());
    }

    DateTime? endedAt;
    if (json['endedAt'] != null) {
      endedAt = DateTime.tryParse(json['endedAt'].toString());
    }

    int? durMinutes;
    if (json['durationMinutes'] != null) {
      durMinutes = int.tryParse(json['durationMinutes'].toString());
    }

    String? vFolderId;
    if (json['vaultFolderId'] is Map) {
      vFolderId = json['vaultFolderId']['_id']?.toString() ??
          json['vaultFolderId']['id']?.toString();
    } else if (json['vaultFolderId'] != null) {
      vFolderId = json['vaultFolderId'].toString();
    }

    final List<String> jAttorneys = [];
    if (json['joinedAttorneys'] is List) {
      for (final item in json['joinedAttorneys'] as List) {
        if (item is Map) {
          final id = item['_id']?.toString() ?? item['id']?.toString();
          if (id != null && id.isNotEmpty) jAttorneys.add(id);
        } else if (item != null) {
          final idStr = item.toString();
          if (idStr.isNotEmpty) jAttorneys.add(idStr);
        }
      }
    }

    final List<String> jParticipants = [];
    if (json['joinedParticipants'] is List) {
      for (final item in json['joinedParticipants'] as List) {
        if (item is Map) {
          final id = item['_id']?.toString() ?? item['id']?.toString();
          if (id != null && id.isNotEmpty) jParticipants.add(id);
        } else if (item != null) {
          final idStr = item.toString();
          if (idStr.isNotEmpty) jParticipants.add(idStr);
        }
      }
    }

    final List<MeetingRecording> recList = [];
    if (json['recordings'] is List) {
      for (final item in json['recordings'] as List) {
        if (item is Map<String, dynamic>) {
          recList.add(MeetingRecording.fromJson(item));
        } else if (item is Map) {
          recList.add(MeetingRecording.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final mId = json['_id']?.toString() ?? json['meetingId']?.toString() ?? '';

    final double? lat = json['latitude'] != null
        ? double.tryParse(json['latitude'].toString())
        : null;
    final double? lng = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString())
        : null;
    final String? locAddr = json['locationAddress']?.toString();

    return MeetingModel(
      id: mId,
      roomName: rName,
      zoomMeetingId: json['zoomMeetingId']?.toString(),
      topic: json['topic']?.toString() ?? 'Govia Consultation',
      joinUrl: json['joinUrl']?.toString(),
      startUrl: json['startUrl']?.toString(),
      password: json['password']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      meetingType: json['meetingType']?.toString() ?? 'INSTANT',
      recordingUrl: json['recordingUrl']?.toString(),
      sessionName: rName,
      token: json['token']?.toString() ??
          json['livekitToken']?.toString() ??
          json['sdkToken']?.toString(),
      livekitUrl: json['livekitUrl']?.toString(),
      callerName: caller ?? 'Citizen User',
      callerPhone: phone,
      callerAvatar: avatar,
      userId: uId,
      hostId: hId,
      category: json['category']?.toString(),
      createdAt: created,
      startTime: startTime,
      durationMinutes: durMinutes,
      timezone: json['timezone']?.toString(),
      agenda: json['agenda']?.toString(),
      endedAt: endedAt,
      recordings: recList,
      joinedAttorneys: jAttorneys,
      joinedParticipants: jParticipants,
      vaultFolderId: vFolderId,
      latitude: lat,
      longitude: lng,
      locationAddress: locAddr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomName': roomName,
      if (zoomMeetingId != null) 'zoomMeetingId': zoomMeetingId,
      'topic': topic,
      if (joinUrl != null) 'joinUrl': joinUrl,
      if (startUrl != null) 'startUrl': startUrl,
      if (password != null) 'password': password,
      'status': status,
      'meetingType': meetingType,
      if (recordingUrl != null) 'recordingUrl': recordingUrl,
      if (sessionName != null) 'sessionName': sessionName,
      if (token != null) 'token': token,
      if (livekitUrl != null) 'livekitUrl': livekitUrl,
      if (callerName != null) 'callerName': callerName,
      if (callerPhone != null) 'callerPhone': callerPhone,
      if (callerAvatar != null) 'callerAvatar': callerAvatar,
      if (userId != null) 'userId': userId,
      if (hostId != null) 'hostId': hostId,
      if (category != null) 'category': category,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (startTime != null) 'startTime': startTime?.toIso8601String(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (timezone != null) 'timezone': timezone,
      if (agenda != null) 'agenda': agenda,
      if (endedAt != null) 'endedAt': endedAt?.toIso8601String(),
      'recordings': recordings.map((r) => r.toJson()).toList(),
      'joinedAttorneys': joinedAttorneys,
      'joinedParticipants': joinedParticipants,
      if (vaultFolderId != null) 'vaultFolderId': vaultFolderId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationAddress != null) 'locationAddress': locationAddress,
    };
  }
}
