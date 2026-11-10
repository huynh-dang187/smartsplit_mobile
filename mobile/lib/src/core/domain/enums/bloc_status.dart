/// Các trạng thái chu kỳ sống tiêu chuẩn của Cubit/BLoC trong SmartSplit.
enum BlocStatus {
  init,
  initial,
  loading,
  checking,
  hasData,
  success,
  error,
  validateError,
}

/// Tiện ích kiểm tra trạng thái nhanh chóng cho tầng Presentation.
extension BlocStatusX on BlocStatus {
  /// Đang ở trạng thái khởi đầu, chưa thực hiện tác vụ nào
  bool get isInitial => this == BlocStatus.init || this == BlocStatus.initial;

  /// Đang trong quá trình tải dữ liệu hoặc kiểm tra
  bool get isLoading => this == BlocStatus.loading || this == BlocStatus.checking;

  /// Tác vụ thành công hoặc đã có dữ liệu hiển thị
  bool get isSuccess => this == BlocStatus.success || this == BlocStatus.hasData;

  /// Đã có dữ liệu sẵn sàng hiển thị
  bool get hasData => this == BlocStatus.hasData;

  /// Gặp lỗi xử lý hoặc lỗi xác thực đầu vào
  bool get isError => this == BlocStatus.error || this == BlocStatus.validateError;

  /// Lỗi validate form đầu vào
  bool get isValidateError => this == BlocStatus.validateError;
}
