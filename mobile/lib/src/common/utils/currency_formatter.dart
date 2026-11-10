import 'package:intl/intl.dart';

/// Bộ tiện ích định dạng tiền tệ VNĐ chuẩn số nguyên cho ứng dụng SmartSplit.
abstract class CurrencyFormatter {
  static final NumberFormat _vndFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberOnlyFormatter = NumberFormat('#,###', 'vi_VN');

  /// Định dạng số nguyên thành chuỗi VNĐ đầy đủ (VD: `150000` -> `150.000 đ`)
  static String formatVnd(num amount) {
    return _vndFormatter.format(amount.round());
  }

  /// Định dạng số kèm dấu cộng/trừ phục vụ hiển thị số dư nợ
  /// - `150000` -> `+150.000 đ`
  /// - `-50000` -> `-50.000 đ`
  /// - `0` -> `0 đ`
  static String formatSignedVnd(num amount) {
    final rounded = amount.round();
    if (rounded > 0) {
      return '+${_vndFormatter.format(rounded)}';
    } else if (rounded < 0) {
      return '-${_vndFormatter.format(rounded.abs())}';
    }
    return _vndFormatter.format(0);
  }

  /// Chỉ định dạng số với dấu chấm phân tách hàng nghìn, không kèm ký hiệu `đ`
  /// (VD: `150000` -> `150.000`)
  static String formatNumberOnly(num amount) {
    return _numberOnlyFormatter.format(amount.round());
  }

  /// Parse chuỗi số tiếng Việt (VD: `150.000` hoặc `150000`) thành số nguyên VNĐ
  static int parseVnd(String text) {
    final cleanText = text.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleanText) ?? 0;
  }
}
