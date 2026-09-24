class LegalPage {
  final String slug;
  final String title;

  LegalPage({
    required this.slug,
    required this.title,
  });

  factory LegalPage.fromJson(Map<String, dynamic> json) {
    return LegalPage(
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
    );
  }
}

class LegalPageDetails {
  final String slug;
  final String title;
  final String content;
  final String updatedAt;

  LegalPageDetails({
    required this.slug,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  factory LegalPageDetails.fromJson(Map<String, dynamic> json) {
    return LegalPageDetails(
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
