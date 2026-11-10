/// Cấu trúc chuẩn hóa kết quả phản hồi nghiệp vụ toàn ứng dụng SmartSplit.
/// 
/// Khớp với định dạng API Contract tại Mục 1 contract.md:
/// - Thành công: `{ "success": true, "message": "...", "data": { ... } }`
/// - Thất bại: `{ "success": false, "message": "...", "errorCode": "...", "errors": [] }`
class BaseResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  const BaseResult({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  /// Tạo kết quả thành công
  factory BaseResult.ok(T data, {String? message}) {
    return BaseResult(
      success: true,
      data: data,
      message: message,
    );
  }

  /// Tạo kết quả thất bại
  factory BaseResult.fail(String message, {String? errorCode, T? data}) {
    return BaseResult(
      success: false,
      message: message,
      errorCode: errorCode,
      data: data,
    );
  }

  /// Parse dữ liệu từ JSON chuẩn Backend Express
  factory BaseResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data) fromJsonT,
  ) {
    final isSuccess = json['success'] == true;
    return BaseResult(
      success: isSuccess,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
      data: isSuccess && json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  bool get isSuccess => success;
  bool get isFailure => !success;
}
