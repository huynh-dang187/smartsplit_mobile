import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/user_model.dart';

/// Quản lý lưu trữ cục bộ bảo mật (Token, Thông tin User) bằng SharedPreferences.
class SecuredStorage {
  final SharedPreferences _prefs;

  static const String _accessTokenKey = 'SMARTSPLIT_ACCESS_TOKEN';
  static const String _currentUserKey = 'SMARTSPLIT_CURRENT_USER';

  SecuredStorage(this._prefs);

  /// Khởi tạo instance bất đồng bộ
  static Future<SecuredStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SecuredStorage(prefs);
  }

  // --- QUẢN LÝ ACCESS TOKEN ---

  /// Lưu trữ JWT accessToken sau khi Login/Register thành công
  Future<bool> saveToken(String token) async {
    return _prefs.setString(_accessTokenKey, token);
  }

  /// Lấy JWT accessToken hiện tại
  String? getToken() {
    return _prefs.getString(_accessTokenKey);
  }

  /// Kiểm tra xem người dùng đã có token đăng nhập chưa
  bool hasToken() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  /// Xóa accessToken
  Future<bool> removeToken() async {
    return _prefs.remove(_accessTokenKey);
  }

  // --- QUẢN LÝ CURRENT USER ---

  /// Lưu trữ đối tượng User hiện tại vào bộ nhớ cục bộ
  Future<bool> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    return _prefs.setString(_currentUserKey, userJson);
  }

  /// Đọc đối tượng User từ bộ nhớ cục bộ
  UserModel? getUser() {
    final userJson = _prefs.getString(_currentUserKey);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Xóa thông tin User
  Future<bool> removeUser() async {
    return _prefs.remove(_currentUserKey);
  }

  /// Đăng xuất: Xóa toàn bộ token và dữ liệu phiên người dùng
  Future<void> clearAll() async {
    await removeToken();
    await removeUser();
  }
}
