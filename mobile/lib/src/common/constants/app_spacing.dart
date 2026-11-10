import 'package:flutter/material.dart';

/// Hệ thống nhịp điệu không gian (Spacing) và bo góc (Border Radius) chuẩn SmartSplit.
/// 
/// Tuân thủ quy chuẩn hệ thống lưới 4pt/8pt từ `ui-ux-pro-max` và nguyên tắc Touch Target
/// tối thiểu 44dp từ `impeccable`.
abstract class AppSpacing {
  // --- 1. LƯỚI KHOẢNG CÁCH (4PT/8PT GRID CONSTANTS) ---
  /// 4.0 dp - Khoảng cách siêu nhỏ (khoảng cách icon với nhãn, padding tag mini)
  static const double xs = 4.0;
  /// 8.0 dp - Khoảng cách nhỏ (padding nút nhỏ, khoảng cách giữa các phần tử phụ)
  static const double sm = 8.0;
  /// 12.0 dp - Khoảng cách trung bình (khoảng cách giữa các dòng thông tin, padding input)
  static const double md = 12.0;
  /// 16.0 dp - Khoảng cách chuẩn (padding lề màn hình, padding thẻ Card)
  static const double lg = 16.0;
  /// 24.0 dp - Khoảng cách lớn (khoảng cách giữa các khối/section)
  static const double xl = 24.0;
  /// 32.0 dp - Khoảng cách cực lớn (khoảng cách tiêu đề lớn, khoảng trắng phân tách chính)
  static const double xxl = 32.0;
  /// 48.0 dp - Khoảng cách tối đa cho phần hero / avatar / bottom actions
  static const double hero = 48.0;

  // --- 2. VÙNG CHẠM TỐI THIỂU (TOUCH TARGET - WCAG & MOBILE UX) ---
  /// Vùng chạm tối thiểu tuyệt đối cho mọi nút bấm, icon bấm được (iOS: 44dp, Android: 48dp)
  static const double minTouchTarget = 44.0;
  /// Chiều cao tiêu chuẩn cho nút bấm chính (CTA button)
  static const double buttonHeight = 48.0;
  /// Chiều cao cho ô nhập liệu tiêu chuẩn
  static const double inputHeight = 52.0;

  // --- 3. BÁN KÍNH BO GÓC (BORDER RADII) ---
  /// 8.0 dp - Bo góc nhỏ: thẻ tag, badge, chip
  static const double radiusSm = 8.0;
  /// 12.0 dp - Bo góc trung bình: ô input, card con, button
  static const double radiusMd = 12.0;
  /// 16.0 dp - Bo góc chuẩn: Card lớn, Container danh sách
  static const double radiusLg = 16.0;
  /// 24.0 dp - Bo góc sheet: Modal Bottom Sheet, Dialog popup
  static const double radiusSheet = 24.0;
  /// 999.0 dp - Bo góc tròn tuyệt đối: Nút dạng Pill, Badge tròn, Avatar
  static const double radiusPill = 999.0;

  // --- 4. TIỆN ÍCH BORDERRADIUS (SẴN DÙNG) ---
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedSheet = BorderRadius.vertical(top: Radius.circular(radiusSheet));
  static const BorderRadius roundedPill = BorderRadius.all(Radius.circular(radiusPill));

  // --- 5. TIỆN ÍCH EDGEINSETS (PADDING LỀ MÀN HÌNH & THẺ) ---
  /// Padding chuẩn toàn màn hình: 16dp ngang
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  /// Padding bên trong thẻ Card chuẩn
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  /// Padding gọn cho item danh sách
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  /// Padding cho Badge trạng thái
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);

  // --- 6. SIZEDBOX KHOẢNG TRỐNG THEO CHIỀU DỌC (VERTICAL GAPS) ---
  static const SizedBox gapVerticalXs = SizedBox(height: xs);
  static const SizedBox gapVerticalSm = SizedBox(height: sm);
  static const SizedBox gapVerticalMd = SizedBox(height: md);
  static const SizedBox gapVerticalLg = SizedBox(height: lg);
  static const SizedBox gapVerticalXl = SizedBox(height: xl);
  static const SizedBox gapVerticalXxl = SizedBox(height: xxl);

  // --- 7. SIZEDBOX KHOẢNG TRỐNG THEO CHIỀU NGANG (HORIZONTAL GAPS) ---
  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);
  static const SizedBox gapHorizontalXl = SizedBox(width: xl);
}
