class PrivateCardsResponse {
  final bool success;
  final String message;
  final Pagination pagination;
  final List<PrivateCard> data;

  PrivateCardsResponse({
    required this.success,
    required this.message,
    required this.pagination,
    required this.data,
  });

  factory PrivateCardsResponse.fromJson(Map<String, dynamic> json) {
    return PrivateCardsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      data: json['data'] != null
          ? List<PrivateCard>.from(
              json['data'].map((x) => PrivateCard.fromJson(x)),
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

class PrivateCard {
  final String id;
  final String cardTitle;
  final String surgeonName;
  final String surgeonSpecialty;
  final bool isVerified;
  final int totalDownloads;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  PrivateCard({
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

  factory PrivateCard.fromJson(Map<String, dynamic> json) {
    return PrivateCard( 
      id: json['_id'] ?? '',
      cardTitle: json['cardTitle'] ?? '',
      surgeonName: json['surgeonName'] ?? '',
      surgeonSpecialty: json['surgeonSpecialty'] ?? '',
      isVerified: json['isVerified'] ?? false,
      totalDownloads: json['totalDownloads'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
