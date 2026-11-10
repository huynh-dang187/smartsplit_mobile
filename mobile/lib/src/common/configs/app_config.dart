/// Cấu hình toàn cục cho ứng dụng SmartSplit.
abstract class AppConfig {
  static const String appName = 'SmartSplit';
  
  /// Base URL kết nối đến Express Backend API.
  /// Lưu ý:
  /// - Android Emulator dùng `http://10.0.2.2:3000/api` để trỏ vào localhost của máy host.
  /// - iOS Simulator dùng `http://127.0.0.1:3000/api` hoặc `http://localhost:3000/api`.
  /// - Thiết bị thật: thay bằng IP mạng nội bộ (VD: `http://192.168.1.x:3000/api`).
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  /// Thời gian chờ kết nối mạng (15 giây)
  static const Duration connectTimeout = Duration(seconds: 15);
  /// Thời gian chờ nhận phản hồi mạng (30 giây - hỗ trợ AI Scanner xử lý ảnh)
  static const Duration receiveTimeout = Duration(seconds: 30);
}
