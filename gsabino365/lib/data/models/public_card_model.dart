class PublicCardsResponse {
  final bool success;
  final String message;
  final Pagination pagination;
  final List<PublicCard> data;

  PublicCardsResponse({
    required this.success,
    required this.message,
    required this.pagination,
    required this.data,
  });

  factory PublicCardsResponse.fromJson(Map<String, dynamic> json) {
    return PublicCardsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      data: json['data'] != null
          ? List<PublicCard>.from(
              json['data'].map((x) => PublicCard.fromJson(x)),
            )
          : [],
    );
  }
}

class Pagination {
  final int total;
  final int limit;
  final int page;
  final int totalPage;

  Pagination({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      page: json['page'] ?? 1,
      totalPage: json['totalPage'] ?? 1,
    );
  }
}

class PublicCard {
  final String id;
  final String cardTitle;
  final String surgeonName;
  final String surgeonSpecialty;
  final bool isVerified;
  final int totalDownloads;
  final bool isFavorite;
  final DateTime updatedAt;
  final DateTime createdAt;

  PublicCard({
    required this.id,
    required this.cardTitle,
    required this.surgeonName,
    required this.surgeonSpecialty,
    required this.isVerified,
    required this.totalDownloads,
    required this.isFavorite,
    required this.updatedAt,
    required this.createdAt,
  });

  factory PublicCard.fromJson(Map<String, dynamic> json) {
    return PublicCard(
      id: json['_id'] ?? '',
      cardTitle: json['cardTitle'] ?? '',
      surgeonName: json['surgeonName'] ?? '',
      surgeonSpecialty: json['surgeonSpecialty'] ?? '',
      isVerified: json['isVerified'] ?? false,
      totalDownloads: json['totalDownloads'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
