class LibraryCardsResponse {
  final bool success;
  final String message;
  final LibraryMeta meta;
  final List<LibraryCard> data;

  LibraryCardsResponse({
    required this.success,
    required this.message,
    required this.meta,
    required this.data,
  });

  factory LibraryCardsResponse.fromJson(Map<String, dynamic> json) {
    return LibraryCardsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      meta: LibraryMeta.fromJson(json['meta'] ?? {}),
      data: json['data'] != null
          ? List<LibraryCard>.from(
              json['data'].map((x) => LibraryCard.fromJson(x)),
            )
          : [],
    );
  }
}

class LibraryMeta {
  final int total;
  final int limit;
  final int page;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  LibraryMeta({
    required this.total,
    required this.limit,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory LibraryMeta.fromJson(Map<String, dynamic> json) {
    return LibraryMeta(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      page: json['page'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

class LibraryCard {
  final String id;
  final String cardTitle;
  final String surgeonName;
  final String surgeonSpecialty;
  final String verificationStatus;
  final int downloadCount;
  final bool isFavorited;
  final DateTime updatedAt;
  final DateTime createdAt;

  LibraryCard({
    required this.id,
    required this.cardTitle,
    required this.surgeonName,
    required this.surgeonSpecialty,
    required this.verificationStatus,
    required this.downloadCount,
    required this.isFavorited,
    required this.updatedAt,
    required this.createdAt,
  });

  factory LibraryCard.fromJson(Map<String, dynamic> json) {
    final surgeon = json['surgeon'] as Map<String, dynamic>? ?? {};
    return LibraryCard(
      id: json['id'] ?? '',
      cardTitle: json['cardTitle'] ?? '',
      surgeonName: surgeon['name'] ?? '',
      surgeonSpecialty: surgeon['specialty'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'UNVERIFIED',
      downloadCount: json['downloadCount'] ?? 0,
      isFavorited: json['isFavorited'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
