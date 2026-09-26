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

  /// Default predefined StoreKit & Google Play consumable gift packages
  static List<GiftPackageModel> get defaultPackages => [
        GiftPackageModel(
          id: 'govia_gift_monthly_1',
          productId: 'govia_gift_monthly_1',
          title: '1 Month Gift Pass',
          plan: 'PREMIUM_MONTHLY',
          billingCycle: 'MONTHLY',
          unitsCount: 1,
          durationDays: 30,
          price: 9.99,
          unitPrice: 9.99,
          description:
              'Single-use 30-day premium emergency protection pass for a family member or client.',
          features: [
            'Unlimited emergency room meetings',
            'Cloud video recording & playback archive',
            '24/7 AI Legal & Safety assistant',
          ],
        ),
        GiftPackageModel(
          id: 'govia_gift_yearly_1',
          productId: 'govia_gift_yearly_1',
          title: '1 Year VIP Pass',
          plan: 'PREMIUM_YEARLY',
          billingCycle: 'YEARLY',
          unitsCount: 1,
          durationDays: 365,
          price: 79.99,
          unitPrice: 79.99,
          badge: 'Best Value',
          discountText: 'Save 33%',
          description:
              'Full 365-day VIP protection pass. Unlocks complete Govia safety network for one full year.',
          features: [
            '365 Days complete safety & legal coverage',
            'Full HD video recording & evidence vault',
            'Direct doctor consultation access',
            'Unlimited priority emergency dispatch',
          ],
        ),
        GiftPackageModel(
          id: 'govia_gift_monthly_3',
          productId: 'govia_gift_monthly_3',
          title: 'Family Pack (3 Gifts)',
          plan: 'PREMIUM_MONTHLY',
          billingCycle: 'MONTHLY',
          unitsCount: 3,
          durationDays: 30,
          price: 26.99,
          unitPrice: 8.99,
          badge: 'Popular',
          discountText: 'Save 10%',
          description:
              '3 separate single-use codes (30 days each). Protect your spouse, children, or parents.',
          features: [
            '3 separate single-use activation codes',
            'Live tracking showing who redeemed each code',
            'Full citizen premium features for each user',
          ],
        ),
        GiftPackageModel(
          id: 'govia_gift_monthly_5',
          productId: 'govia_gift_monthly_5',
          title: 'Team Pack (5 Gifts)',
          plan: 'PREMIUM_MONTHLY',
          billingCycle: 'MONTHLY',
          unitsCount: 5,
          durationDays: 30,
          price: 44.99,
          unitPrice: 8.99,
          discountText: 'Save 10%',
          description:
              '5 separate single-use codes (30 days each) for small offices, teams, or extended family.',
          features: [
            '5 individual single-use activation codes',
            'Real-time redemption tracking with recipient info',
            'Full premium privileges per member',
          ],
        ),
        GiftPackageModel(
          id: 'govia_gift_monthly_10',
          productId: 'govia_gift_monthly_10',
          title: 'Community Pack (10 Gifts)',
          plan: 'PREMIUM_MONTHLY',
          billingCycle: 'MONTHLY',
          unitsCount: 10,
          durationDays: 30,
          price: 79.99,
          unitPrice: 7.99,
          badge: 'Group Deal',
          discountText: 'Save 20%',
          description:
              '10 individual gift passes. Ideal for attorneys gifting clients, organizations, or communities.',
          features: [
            '10 unique single-use activation codes',
            'Complete dashboard tracking each recipient',
            'Maximum savings (\$7.99/code)',
          ],
        ),
      ];
}
