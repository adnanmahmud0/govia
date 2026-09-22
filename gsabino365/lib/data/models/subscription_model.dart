class SubscriptionModel {
  final String? id;
  final String? userId;
  final String plan;
  final String status;
  final String? platform;
  final String? environment;
  final String? productId;
  final bool? autoRenewing;
  final DateTime? currentPeriodEnd;

  SubscriptionModel({
    this.id,
    this.userId,
    required this.plan,
    required this.status,
    this.platform,
    this.environment,
    this.productId,
    this.autoRenewing,
    this.currentPeriodEnd,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'],
      userId: json['userId'],
      plan: json['plan'] ?? 'FREE',
      status: json['status'] ?? 'ACTIVE',
      platform: json['platform'],
      environment: json['environment'],
      productId: json['productId'],
      autoRenewing: json['autoRenewing'],
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'])
          : null,
    );
  }

  bool get isPremium => plan == 'PREMIUM' || plan == 'ENTERPRISE';
  bool get isEnterprise => plan == 'ENTERPRISE';
}
