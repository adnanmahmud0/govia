class GiftPackageModel {
  final String id;
  final String productId;
  final String title;
  final String plan;
  final String billingCycle;
  final int unitsCount;
  final int durationDays;
  final double price;
  final double unitPrice;
  final String? badge;
  final String? discountText;
  final String description;
  final List<String> features;

  GiftPackageModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.plan,
    required this.billingCycle,
    required this.unitsCount,
    required this.durationDays,
    required this.price,
    required this.unitPrice,
    this.badge,
    this.discountText,
    required this.description,
    required this.features,
  });

  factory GiftPackageModel.fromJson(Map<String, dynamic> json) {
    return GiftPackageModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      plan: json['plan']?.toString() ?? 'PREMIUM_MONTHLY',
      billingCycle: json['billingCycle']?.toString() ?? 'MONTHLY',
      unitsCount: (json['unitsCount'] as num?)?.toInt() ?? 1,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      badge: json['badge']?.toString(),
      discountText: json['discountText']?.toString(),
      description: json['description']?.toString() ?? '',
      features: (json['features'] as List<dynamic>?)
              ?.map((f) => f.toString())
              .toList() ??
          [],
    );
  }
}
