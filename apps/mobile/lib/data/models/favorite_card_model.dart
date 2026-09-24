class FavoriteCardsResponse {
  final bool success;
  final String message;
  final Pagination pagination;
  final List<FavoriteCard> data;

  FavoriteCardsResponse({
    required this.success,
    required this.message,
    required this.pagination,
    required this.data,
  });

  factory FavoriteCardsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteCardsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      data: json['data'] != null
          ? List<FavoriteCard>.from(
              json['data'].map((x) => FavoriteCard.fromJson(x)),
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

class FavoriteCard {
  final String id;
  final String cardTitle;
  final String surgeonName;
  final String surgeonSpecialty;
  final bool isVerified;
  final int totalDownloads;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  FavoriteCard({
    required this.id,
    required this.cardTitle,
    required this.surgeonName,
    required this.surgeonSpecialty,
    required this.isVerified,
    required this.totalDownloads,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,   
  });

  factory FavoriteCard.fromJson(Map<String, dynamic> json) {
    return FavoriteCard( 
      id: json['id'] ?? json['_id'] ?? '',
      cardTitle: json['cardTitle'] ?? '',
      surgeonName: json['surgeon']?['name'] ?? json['surgeon']?['fullName'] ?? json['surgeonName'] ?? '',
      surgeonSpecialty: json['surgeon']?['specialty'] ?? json['surgeonSpecialty'] ?? '',
      isVerified: json['verificationStatus'] == 'VERIFIED' || json['isVerified'] == true,
      totalDownloads: json['downloadCount'] ?? json['totalDownloads'] ?? 0,
      isFavorite: json['isFavorited'] ?? json['isFavorite'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
