class CardCountModel {
  final int allCardsCount;
  final int myCardsCount;

  CardCountModel({required this.allCardsCount, required this.myCardsCount});

  factory CardCountModel.fromJson(Map<String, dynamic> json) {
    return CardCountModel(
      allCardsCount: json['publicCards'] ?? 0,
      myCardsCount: json['myCards'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'publicCards': allCardsCount, 'myCards': myCardsCount};
  }
}
