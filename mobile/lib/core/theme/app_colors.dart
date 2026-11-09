import 'package:flutter/material.dart';

/// Bảng màu chuẩn Semantic Tokens của ứng dụng SmartSplit.
/// 
/// Tuân thủ nguyên tắc thiết kế Operate Mode (Fintech) và chuẩn tương phản WCAG AA (>= 4.5:1).
/// Toàn bộ widget trong ứng dụng PHẢI dùng các hằng số màu tại đây thay vì viết `Color(0xFF...)` trực tiếp.
abstract class AppColors {
  // --- 1. MÀU THƯƠNG HIỆU CHỦ ĐẠO (BRAND & PRIMARY) ---
  /// Màu chủ đạo: Xanh ngọc lục bảo (Emerald Green) biểu trưng cho tài chính minh bạch, bền vững
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryLight = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primarySurface = Color(0xFFECFDF5); // Emerald 50

  // --- 2. MÀU PHỤ TRỢ & CẤU TRÚC (SECONDARY & NEUTRAL) ---
  /// Màu phụ trợ: Deep Navy / Slate tạo chiều sâu và cấu trúc vững chãi
  static const Color secondary = Color(0xFF0F172A); // Slate 900
  static const Color secondaryLight = Color(0xFF1E293B); // Slate 800
  static const Color secondaryMuted = Color(0xFF334155); // Slate 700

  // --- 3. BỀ MẶT & NỀN (BACKGROUND & SURFACE) ---
  /// Nền app: Slate 50 tạo cảm giác dịu mắt, tách bạch với các thẻ Card trắng
  static const Color background = Color(0xFFF8FAFC);
  /// Nền thẻ/Card: Trắng tinh khôi để nâng đỡ nội dung số học
  static const Color surface = Color(0xFFFFFFFF);
  /// Nền phụ (chips, input background): Slate 100
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // --- 4. ĐƯỜNG VIỀN & PHÂN CÁCH (BORDER & DIVIDER) ---
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100
  static const Color divider = Color(0xFFE2E8F0);

  // --- 5. MÀU VĂN BẢN (TYPOGRAPHY TOKENS - WCAG AA & AAA) ---
  /// Chữ chính: Đen Slate đậm (tương phản > 15:1 trên nền trắng)
  static const Color textPrimary = Color(0xFF0F172A);
  /// Chữ phụ: Xám trung tính (tương phản > 4.6:1 trên nền trắng)
  static const Color textSecondary = Color(0xFF64748B);
  /// Chữ mờ: Placeholder, timestamp phụ
  static const Color textTertiary = Color(0xFF94A3B8);
  /// Chữ trên nền màu tối/Primary
  static const Color textWhite = Color(0xFFFFFFFF);

  // --- 6. TRẠNG THÁI NGHIỆP VỤ 1: CHỦ NỢ (CREDITOR / netBalance > 0) ---
  /// Biểu trưng cho cảm giác tích cực khi được nhận lại tiền
  static const Color creditorGreen = Color(0xFF059669);
  static const Color creditorBg = Color(0xFFECFDF5);
  static const Color creditorBorder = Color(0xFFA7F3D0);
  /// Màu text trên nền creditorBg (đạt tỉ lệ tương phản 5.3:1)
  static const Color creditorText = Color(0xFF047857);

  // --- 7. TRẠNG THÁI NGHIỆP VỤ 2: CON NỢ (DEBTOR / netBalance < 0) ---
  /// Đỏ san hô thúc đẩy hành động trả nợ nhưng không gây chói/hoảng sợ
  static const Color debtorRed = Color(0xFFEF4444);
  static const Color debtorBg = Color(0xFFFEF2F2);
  static const Color debtorBorder = Color(0xFFFECACA);
  /// Màu text trên nền debtorBg (đạt tỉ lệ tương phản 5.2:1)
  static const Color debtorText = Color(0xFFB91C1C);

  // --- 8. TRẠNG THÁI NGHIỆP VỤ 3: SÒNG PHẲNG (SETTLED / netBalance == 0) ---
  /// Xám đá phiến trung tính biểu thị trạng thái không nợ nần
  static const Color settledSlate = Color(0xFF64748B);
  static const Color settledBg = Color(0xFFF1F5F9);
  static const Color settledBorder = Color(0xFFCBD5E1);
  static const Color settledText = Color(0xFF475569);

  // --- 9. TRẠNG THÁI NGHIỆP VỤ 4: CẢNH BÁO LỆCH TIỀN BILL (isDiscrepancy == true) ---
  /// Vàng hổ phách cảnh báo AI nhận diện sai lệch tổng tiền
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningBorder = Color(0xFFFCD34D);
  /// Màu text trên nền warningBg (tương phản > 5:1)
  static const Color warningText = Color(0xFF92400E);

  // --- 10. TRẠNG THÁI NGHIỆP VỤ 5: AI MAGIC & VIETQR ACCENT ---
  /// Tím ánh điện tử biểu trưng cho tính năng AI Scanner
  static const Color aiAccent = Color(0xFF6366F1); // Indigo 500
  static const Color aiAccentLight = Color(0xFFEEF2FF); // Indigo 50
  static const Color aiAccentDark = Color(0xFF4F46E5); // Indigo 600
  /// Màu nhận diện thương hiệu VietQR chuẩn Napas
  static const Color vietQrPrimary = Color(0xFF0054A6);
  static const Color vietQrAccent = Color(0xFFF37021);

  // --- 11. HÀM TRỢ GIÚP DỰA TRÊN NGHIỆP VỤ (BUSINESS HELPERS) ---
  /// Trả về màu biểu thị theo số dư nợ
  static Color getDebtColor(int netBalance) {
    if (netBalance > 0) return creditorGreen;
    if (netBalance < 0) return debtorRed;
    return settledSlate;
  }

  /// Trả về màu nền badge theo số dư nợ
  static Color getDebtBgColor(int netBalance) {
    if (netBalance > 0) return creditorBg;
    if (netBalance < 0) return debtorBg;
    return settledBg;
  }

  /// Trả về màu viền badge theo số dư nợ
  static Color getDebtBorderColor(int netBalance) {
    if (netBalance > 0) return creditorBorder;
    if (netBalance < 0) return debtorBorder;
    return settledBorder;
  }

  /// Trả về màu chữ badge chuẩn tương phản theo số dư nợ
  static Color getDebtTextColor(int netBalance) {
    if (netBalance > 0) return creditorText;
    if (netBalance < 0) return debtorText;
    return settledText;
  }

  /// Chuỗi mô tả trạng thái nợ tiếng Việt
  static String getDebtStatusText(int netBalance) {
    if (netBalance > 0) return 'Bạn được nhận lại';
    if (netBalance < 0) return 'Bạn cần trả';
    return 'Đã sòng phẳng';
  }
}
