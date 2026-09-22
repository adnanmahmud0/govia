class ResponseModel<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ResponseModel({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });

  factory ResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonModel,
  ) {
    return ResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      data: fromJsonModel != null && json['data'] != null
          ? fromJsonModel(json['data'])
          : json['data'],
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'statusCode': statusCode,
    };
  }
}
