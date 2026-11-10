import '../utils/currency_formatter.dart';

/// Extension mở rộng cho kiểu `num` và `int` để định dạng tiền tệ trực tiếp.
extension NumX on num {
  /// Chuyển thành chuỗi tiền tệ VNĐ (VD: `150000.toVnd()` -> `"150.000 đ"`)
  String toVnd() => CurrencyFormatter.formatVnd(this);

  /// Chuyển thành chuỗi tiền tệ VNĐ có dấu +/- (VD: `150000.toSignedVnd()` -> `"+150.000 đ"`)
  String toSignedVnd() => CurrencyFormatter.formatSignedVnd(this);

  /// Chỉ định dạng dấu chấm phân cách hàng nghìn (VD: `150000.toNumberOnly()` -> `"150.000"`)
  String toNumberOnly() => CurrencyFormatter.formatNumberOnly(this);
}
