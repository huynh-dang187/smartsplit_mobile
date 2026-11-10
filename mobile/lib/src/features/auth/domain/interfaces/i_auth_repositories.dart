import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/bank_info_model.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';

/// Hợp đồng Interface định nghĩa các tác vụ xác thực và thông tin người dùng.
abstract interface class IAuthRepositories {
  /// Đăng ký tài khoản mới kèm thông tin ngân hàng Napas (tùy chọn)
  Future<BaseResult<UserModel>> register({
    required String name,
    required String email,
    required String password,
    BankInfoModel? bankInfo,
  });

  /// Đăng nhập tài khoản bằng email và mật khẩu
  Future<BaseResult<UserModel>> login({
    required String email,
    required String password,
  });

  /// Cập nhật tên, ảnh đại diện hoặc thông tin tài khoản ngân hàng thụ hưởng
  Future<BaseResult<UserModel>> updateProfile({
    String? name,
    String? avatarUrl,
    BankInfoModel? bankInfo,
  });
}
