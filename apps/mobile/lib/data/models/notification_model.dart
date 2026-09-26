class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String subtitle;
  final String resourceType;
  final String resourceId;
  final NotificationLink? link;
  final bool isRead;
  final DateTime? readAt;
  final String? icon;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.resourceType,
    required this.resourceId,
    this.link,
    required this.isRead,
    this.readAt,
    this.icon,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      resourceType: json['resourceType'] ?? '',
      resourceId: json['resourceId'] ?? '',
      link: json['link'] != null ? NotificationLink.fromJson(json['link']) : null,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      icon: json['icon'],
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? subtitle,
    String? resourceType,
    String? resourceId,
    NotificationLink? link,
    bool? isRead,
    DateTime? readAt,
    String? icon,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Helper Getters for Rich UI & Dynamic Routing ──
  String? get callerName => metadata?['callerName']?.toString();
  String? get callerRole => metadata?['callerRole']?.toString();
  String? get callerAvatar => metadata?['callerAvatar']?.toString();
  String? get location => metadata?['location']?.toString();
  String? get topic => metadata?['topic']?.toString();
  String? get category => metadata?['category']?.toString();
  String? get folderName => metadata?['folderName']?.toString();
  bool get isLive => metadata?['isLive'] == true;

  bool get isIncident {
    final t = type.toLowerCase();
    final rt = resourceType.toLowerCase();
    final cat = (category ?? '').toUpperCase();
    final titleLower = title.toLowerCase();
    return t == 'emergency' ||
        t == 'dispatch' ||
        t == 'encounter' ||
        rt == 'encounter' ||
        cat == 'EMERGENCY' ||
        titleLower.contains('emergency') ||
        titleLower.contains('encounter') ||
        titleLower.contains('incident') ||
        titleLower.contains('stop alert');
  }

  bool get isMeeting {
    final t = type.toLowerCase();
    final rt = resourceType.toLowerCase();
    final titleLower = title.toLowerCase();
    return rt == 'meeting' ||
        t == 'consultation' ||
        t == 'duty' ||
        titleLower.contains('consultation') ||
        titleLower.contains('hearing');
  }

  bool get isVault {
    final t = type.toLowerCase();
    final rt = resourceType.toLowerCase();
    final titleLower = title.toLowerCase();
    return rt == 'vault' ||
        t == 'vault' ||
        t == 'case' ||
        t == 'document' ||
        titleLower.contains('vault') ||
        titleLower.contains('folder') ||
        titleLower.contains('evidence');
  }

  bool get isRecording {
    final t = type.toLowerCase();
    final rt = resourceType.toLowerCase();
    final titleLower = title.toLowerCase();
    return rt == 'recording' ||
        t == 'recording' ||
        titleLower.contains('recording');
  }

  String get badgeLabel {
    if (isIncident) return 'EMERGENCY ENCOUNTER';
    if (isRecording) return 'SESSION RECORDING';
    if (isVault) return 'EVIDENCE VAULT';
    if (isMeeting) return 'CONSULTATION';
    if (type.toLowerCase() == 'duty') return 'DUTY BRIEFING';
    if (type.toLowerCase() == 'bail') return 'SURETY & BAIL';
    return type.isNotEmpty ? type.toUpperCase().replaceAll('_', ' ') : 'NOTIFICATION';
  }

  String get actionLabel {
    if (isIncident) return 'Join Live Encounter';
    if (isRecording) return 'Open in Evidence Vault';
    if (isVault) return 'View Case Vault';
    if (isMeeting) return isLive ? 'Join Consultation Call' : 'View Schedule';
    if (type.toLowerCase() == 'duty') return 'View Duty Schedule';
    if (type.toLowerCase() == 'bail') return 'View Active Requests';
    return 'View Details';
  }
}

class NotificationLink {
  final String label;
  final String url;
  NotificationLink({required this.label, required this.url});

  factory NotificationLink.fromJson(Map<String, dynamic> json) {
    return NotificationLink(
      label: json['label'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> data;
  final NotificationMeta meta;

  NotificationResponse({required this.data, required this.meta});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      data: (json['data'] as List? ?? [])
          .map((e) => NotificationModel.fromJson(e))
          .toList(),
      meta: NotificationMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class NotificationMeta {
  final int limit;
  final String? nextCursor;
  final bool hasMore;
  final int unreadCount;

  NotificationMeta({
    required this.limit,
    this.nextCursor,
    required this.hasMore,
    required this.unreadCount,
  });

  factory NotificationMeta.fromJson(Map<String, dynamic> json) {
    return NotificationMeta(
      limit: json['limit'] ?? 20,
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] ?? false,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
