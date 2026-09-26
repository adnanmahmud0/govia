import 'package:intl/intl.dart';

class GiftCodeModel {
  final String id;
  final String code;
  final String? batchId;
  final String plan;
  final String billingCycle;
  final int durationDays;
  final double pricePerUnit;
  final String status;
  final bool isRedeemed;
  final String? redeemedByName;
  final String? redeemedByEmail;
  final String? redeemedByAvatar;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  GiftCodeModel({
    required this.id,
    required this.code,
    this.batchId,
    required this.plan,
    required this.billingCycle,
    required this.durationDays,
    required this.pricePerUnit,
    required this.status,
    required this.isRedeemed,
    this.redeemedByName,
    this.redeemedByEmail,
    this.redeemedByAvatar,
    this.redeemedAt,
    this.expiresAt,
    this.createdAt,
  });

  factory GiftCodeModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    final isRedeemedVal = json['isRedeemed'] == true ||
        json['status']?.toString().toUpperCase() == 'REDEEMED';

    return GiftCodeModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      batchId: json['batchId']?.toString(),
      plan: json['plan']?.toString() ?? 'PREMIUM_MONTHLY',
      billingCycle: json['billingCycle']?.toString() ?? 'MONTHLY',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString().toUpperCase() ?? 'AVAILABLE',
      isRedeemed: isRedeemedVal,
      redeemedByName: json['redeemedByName']?.toString(),
      redeemedByEmail: json['redeemedByEmail']?.toString(),
      redeemedByAvatar: json['redeemedByAvatar']?.toString(),
      redeemedAt: parseDate(json['redeemedAt']),
      expiresAt: parseDate(json['expiresAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  String get formattedPlanTitle {
    if (plan.contains('YEARLY') || durationDays >= 365) {
      return '1 Year VIP Pass';
    }
    return '1 Month Safety Pass';
  }

  String get formattedRedeemedDate {
    if (redeemedAt == null) return '';
    return DateFormat('MMM d, y • h:mm a').format(redeemedAt!.toLocal());
  }

  String get formattedCreatedDate {
    if (createdAt == null) return '';
    return DateFormat('MMM d, y').format(createdAt!.toLocal());
  }
}

class GiftCodePreviewModel {
  final bool valid;
  final String code;
  final String plan;
  final int durationDays;
  final String purchaserName;
  final String purchaserRole;
  final DateTime? expiresAt;
  final List<String> features;

  GiftCodePreviewModel({
    required this.valid,
    required this.code,
    required this.plan,
    required this.durationDays,
    required this.purchaserName,
    required this.purchaserRole,
    this.expiresAt,
    required this.features,
  });

  factory GiftCodePreviewModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    return GiftCodePreviewModel(
      valid: json['valid'] == true,
      code: json['code']?.toString() ?? '',
      plan: json['plan']?.toString() ?? 'PREMIUM_MONTHLY',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      purchaserName: json['purchaserName']?.toString() ?? 'Govia Member',
      purchaserRole: json['purchaserRole']?.toString() ?? 'CITIZEN',
      expiresAt: parseDate(json['expiresAt']),
      features: (json['features'] as List<dynamic>?)
              ?.map((f) => f.toString())
              .toList() ??
          [],
    );
  }
}
