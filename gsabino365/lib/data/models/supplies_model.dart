class SuppliesResponse {
  final bool success;
  final int statusCode;
  final Pagination? pagination;
  final List<SuppliesModel> supplies;

  SuppliesResponse({
    required this.success,
    required this.statusCode,
    this.pagination,
    required this.supplies,
  });

  factory SuppliesResponse.fromJson(Map<String, dynamic> json) {
    // Check multiple potential locations for the list
    var listData = json['supplies'] ?? json['data'];

    // If it's still null or not a list, it might be an empty response
    List<dynamic> list = [];
    if (listData is List) {
      list = listData;
    } else if (listData is Map && listData['supplies'] is List) {
      list = listData['supplies'];
    }

    return SuppliesResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
      supplies: list
          .map((e) => SuppliesModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'statusCode': statusCode,
      'pagination': pagination?.toJson(),
      'supplies': supplies.map((e) => e.toJson()).toList(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'limit': limit,
      'page': page,
      'totalPage': totalPage,
    };
  }
}

class SuppliesModel {
  final String id;
  final String name;

  SuppliesModel({required this.id, required this.name});

  factory SuppliesModel.fromJson(Map<String, dynamic> json) {
    return SuppliesModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name};
  }
}
