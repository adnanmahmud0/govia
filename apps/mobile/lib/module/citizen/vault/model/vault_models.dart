import 'package:flutter/material.dart';
import 'package:gsabino365/config/constants/api_constants.dart';
import 'package:intl/intl.dart';

class VaultFolderModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> containedCategories;
  final DateTime? incidentDate;
  final String location;
  final bool isArchived;
  final int itemCount;
  final Map<String, int> counts;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isReadOnly;
  final Map<String, dynamic>? sharedBy;
  final List<dynamic> sharedWith;
  final List<String> linkedMeetingIds;

  VaultFolderModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'ENCOUNTER',
    this.containedCategories = const [],
    this.incidentDate,
    this.location = '',
    this.isArchived = false,
    this.itemCount = 0,
    this.counts = const {'video': 0, 'audio': 0, 'image': 0, 'doc': 0},
    this.createdAt,
    this.updatedAt,
    this.isReadOnly = false,
    this.sharedBy,
    this.sharedWith = const [],
    this.linkedMeetingIds = const [],
  });

  String? get sharedByName => sharedBy?['name']?.toString();
  String? get sharedByRole => sharedBy?['role']?.toString();
  String? get sharedByAvatar => sharedBy?['profilePicture']?.toString() ?? sharedBy?['image']?.toString();

  factory VaultFolderModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    final countsJson = json['counts'] as Map<String, dynamic>? ?? {};
    final counts = <String, int>{
      'video': (countsJson['video'] as num?)?.toInt() ?? 0,
      'audio': (countsJson['audio'] as num?)?.toInt() ?? 0,
      'image': (countsJson['image'] as num?)?.toInt() ?? 0,
      'doc': (countsJson['doc'] as num?)?.toInt() ?? 0,
    };

    final rawContained = json['containedCategories'] as List<dynamic>? ?? [];
    final containedList = rawContained.map((e) => e.toString().toUpperCase()).toList();
    final rawSharedWith = json['sharedWith'] as List<dynamic>? ?? [];
    final rawLinked = json['linkedMeetingIds'] as List<dynamic>? ?? [];
    final linkedMeetingIds = rawLinked.map((e) => e.toString()).toList();

    Map<String, dynamic>? sharedBy;
    if (json['sharedBy'] is Map) {
      sharedBy = Map<String, dynamic>.from(json['sharedBy'] as Map);
    } else if (json['userId'] is Map) {
      sharedBy = Map<String, dynamic>.from(json['userId'] as Map);
    }

    return VaultFolderModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Untitled Folder').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'ENCOUNTER').toString().toUpperCase(),
      containedCategories: containedList,
      incidentDate: parseDate(json['incidentDate']),
      location: (json['location'] ?? '').toString(),
      isArchived: json['isArchived'] == true,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      counts: counts,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      isReadOnly: json['isReadOnly'] == true,
      sharedBy: sharedBy,
      sharedWith: rawSharedWith,
      linkedMeetingIds: linkedMeetingIds,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case 'ENCOUNTER':
        return 'GoVia Encounters';
      case 'EMERGENCY':
        return 'Emergency SOS';
      case 'CONSULTATION':
        return 'Consultations';
      case 'UPLOADED':
        return 'Uploaded Evidence';
      default:
        return 'Incident Case';
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'ENCOUNTER':
        return const Color(0xFF1550A6);
      case 'EMERGENCY':
        return const Color(0xFFDC2626);
      case 'CONSULTATION':
        return const Color(0xFF7C3AED);
      case 'UPLOADED':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF475569);
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'ENCOUNTER':
        return Icons.videocam_rounded;
      case 'EMERGENCY':
        return Icons.warning_amber_rounded;
      case 'CONSULTATION':
        return Icons.calendar_month_rounded;
      case 'UPLOADED':
        return Icons.cloud_upload_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  String get formattedDate {
    final d = incidentDate ?? createdAt;
    if (d == null) return 'Date unknown';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(d.toLocal());
  }

  String get evidenceSummary {
    if (itemCount == 0) return 'No evidence files';
    final parts = <String>[];
    if ((counts['video'] ?? 0) > 0) parts.add('${counts['video']} Video${counts['video']! > 1 ? 's' : ''}');
    if ((counts['image'] ?? 0) > 0) parts.add('${counts['image']} Photo${counts['image']! > 1 ? 's' : ''}');
    if ((counts['audio'] ?? 0) > 0) parts.add('${counts['audio']} Audio');
    if ((counts['doc'] ?? 0) > 0) parts.add('${counts['doc']} Doc${counts['doc']! > 1 ? 's' : ''}');
    if (parts.isEmpty) return '$itemCount item${itemCount > 1 ? 's' : ''}';
    return '$itemCount item${itemCount > 1 ? 's' : ''} • ${parts.join(', ')}';
  }
}

class VaultItemModel {
  final String id;
  final String folderId;
  final String title;
  final String description;
  final String category; // 'ENCOUNTER' | 'EMERGENCY' | 'CONSULTATION' | 'UPLOADED'
  final String subCategory;
  final String importance; // 'CRITICAL' | 'HIGH' | 'SUPPORTING' | 'GENERAL'
  final String fileType; // 'VIDEO', 'AUDIO', 'IMAGE', 'DOCUMENT'
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final int duration;
  final String rawDuration;
  final Map<String, dynamic>? meeting;
  final DateTime? createdAt;

  VaultItemModel({
    required this.id,
    required this.folderId,
    this.title = '',
    this.description = '',
    this.category = 'UPLOADED',
    this.subCategory = '',
    this.importance = 'GENERAL',
    this.fileType = 'VIDEO',
    required this.fileUrl,
    this.fileSize = 0,
    this.mimeType = '',
    this.duration = 0,
    this.rawDuration = '',
    this.meeting,
    this.createdAt,
  });

  factory VaultItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    int parseDuration(dynamic d) {
      if (d == null) return 0;
      if (d is num) return d.toInt();
      final str = d.toString();
      final match = RegExp(r'\d+').firstMatch(str);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 0;
      }
      return 0;
    }

    int parseSize(dynamic s) {
      if (s == null) return 0;
      if (s is num) return s.toInt();
      return int.tryParse(s.toString()) ?? 0;
    }

    String parseId(dynamic val) {
      if (val == null) return '';
      if (val is Map) return (val['_id'] ?? val['id'] ?? '').toString();
      return val.toString();
    }

    Map<String, dynamic>? meetingMap;
    if (json['meetingId'] is Map<String, dynamic>) {
      meetingMap = json['meetingId'] as Map<String, dynamic>;
    } else if (json['meeting'] is Map<String, dynamic>) {
      meetingMap = json['meeting'] as Map<String, dynamic>;
    }

    // Determine category: ENCOUNTER, EMERGENCY, CONSULTATION, UPLOADED
    String resolvedCategory = (json['category'] ?? '').toString().toUpperCase();
    if (resolvedCategory.isEmpty || !['ENCOUNTER', 'EMERGENCY', 'CONSULTATION', 'UPLOADED'].contains(resolvedCategory)) {
      if (meetingMap != null) {
        resolvedCategory = (meetingMap['category'] ?? '').toString().toUpperCase();
      }
      if (resolvedCategory.isEmpty || !['ENCOUNTER', 'EMERGENCY', 'CONSULTATION', 'UPLOADED'].contains(resolvedCategory)) {
        final titleStr = (json['title'] ?? meetingMap?['topic'] ?? '').toString().toLowerCase();
        if (titleStr.contains('emergency')) {
          resolvedCategory = 'EMERGENCY';
        } else if (titleStr.contains('police') || titleStr.contains('encounter') || titleStr.contains('govia')) {
          resolvedCategory = 'ENCOUNTER';
        } else {
          resolvedCategory = json['fileType'] == 'VIDEO' ? 'ENCOUNTER' : 'UPLOADED';
        }
      }
    }

    String fileUrl = (json['fileUrl'] ?? '').toString();
    if (fileUrl.isEmpty && meetingMap != null) {
      fileUrl = (meetingMap['recordingUrl'] ?? meetingMap['joinUrl'] ?? '').toString();
      if (fileUrl.isEmpty && meetingMap['_id'] != null) {
        fileUrl = 'https://recordings.govia.ai/play/${meetingMap['_id']}';
      }
    }

    return VaultItemModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      folderId: parseId(json['folderId']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: resolvedCategory,
      subCategory: (json['subCategory'] ?? '').toString(),
      importance: (json['importance'] ?? 'GENERAL').toString().toUpperCase(),
      fileType: (json['fileType'] ?? 'VIDEO').toString().toUpperCase(),
      fileUrl: fileUrl,
      fileSize: parseSize(json['fileSize']),
      mimeType: (json['mimeType'] ?? '').toString(),
      duration: parseDuration(json['duration']),
      rawDuration: (json['duration'] ?? '').toString(),
      meeting: meetingMap,
      createdAt: parseDate(json['createdAt']),
    );
  }

  String get fullUrl => ApiConstants.getFileUrl(fileUrl);

  String get displayTitle {
    if (title.isNotEmpty) return title;
    if (meeting != null) {
      final titleFromMeeting = meeting?['title'] ?? meeting?['topic'] ?? meeting?['meetingType'];
      if (titleFromMeeting != null && titleFromMeeting.toString().isNotEmpty) {
        return titleFromMeeting.toString();
      }
    }
    switch (category) {
      case 'ENCOUNTER':
        return 'GoVia Encounter Recording';
      case 'EMERGENCY':
        return 'Emergency SOS Incident Log';
      case 'CONSULTATION':
        return 'Consultation Session Recording';
      default:
        switch (fileType) {
          case 'VIDEO':
            return 'Uploaded Video Proof';
          case 'AUDIO':
            return 'Voice Memo / Audio Evidence';
          case 'IMAGE':
            return 'Incident Photo Proof';
          case 'DOCUMENT':
            return 'Attached Case Document';
          default:
            return 'Uploaded Evidence';
        }
    }
  }

  // ─── Category Helpers ─────────────────────────────────────────────
  String get categoryDisplayName {
    switch (category) {
      case 'ENCOUNTER':
        return 'GoVia Encounter';
      case 'EMERGENCY':
        return 'Emergency SOS';
      case 'CONSULTATION':
        return 'Consultation';
      case 'UPLOADED':
        return 'Uploaded Evidence';
      default:
        return category;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'ENCOUNTER':
        return const Color(0xFF1550A6);
      case 'EMERGENCY':
        return const Color(0xFFDC2626);
      case 'CONSULTATION':
        return const Color(0xFF7C3AED);
      case 'UPLOADED':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF475569);
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case 'ENCOUNTER':
        return Icons.videocam_rounded;
      case 'EMERGENCY':
        return Icons.warning_amber_rounded;
      case 'CONSULTATION':
        return Icons.calendar_month_rounded;
      case 'UPLOADED':
        return Icons.cloud_upload_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // ─── Importance Helpers (for UPLOADED evidence) ────────────────────
  String get importanceDisplayName {
    switch (importance) {
      case 'CRITICAL':
        return 'Critical Proof';
      case 'HIGH':
        return 'High Importance';
      case 'SUPPORTING':
        return 'Supporting Proof';
      case 'GENERAL':
      default:
        return 'General Info';
    }
  }

  Color get importanceColor {
    switch (importance) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'SUPPORTING':
        return const Color(0xFF2563EB);
      case 'GENERAL':
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData get importanceIcon {
    switch (importance) {
      case 'CRITICAL':
        return Icons.error_rounded;
      case 'HIGH':
        return Icons.priority_high_rounded;
      case 'SUPPORTING':
        return Icons.verified_user_rounded;
      case 'GENERAL':
      default:
        return Icons.info_outline_rounded;
    }
  }

  String get formattedDuration {
    if (rawDuration.isNotEmpty) {
      if (rawDuration.contains('min') || rawDuration.contains('sec') || rawDuration.contains(':')) {
        return rawDuration;
      }
    }
    if (duration <= 0) return rawDuration.isNotEmpty ? rawDuration : '';
    final minutes = (duration / 60).floor();
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    if (createdAt == null) return '';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt!.toLocal());
  }

  IconData get fileIcon {
    switch (fileType) {
      case 'VIDEO':
        return Icons.play_circle_fill_rounded;
      case 'AUDIO':
        return Icons.mic_rounded;
      case 'IMAGE':
        return Icons.image_rounded;
      case 'DOCUMENT':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get fileColor {
    switch (fileType) {
      case 'VIDEO':
        return const Color(0xFF1550A6);
      case 'AUDIO':
        return const Color(0xFF7C3AED);
      case 'IMAGE':
        return const Color(0xFF059669);
      case 'DOCUMENT':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }
}
