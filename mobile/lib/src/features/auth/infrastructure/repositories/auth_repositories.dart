import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/datasources/local/secured_storage.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/datasources/network/api/restful_request.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/bank_info_model.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';
import '../../domain/interfaces/i_auth_repositories.dart';
import '../paths/auth_path.dart';

/// Triển khai thực tế các API xác thực người dùng.
class AuthRepositories implements IAuthRepositories {
  final RestfulRequest _restfulRequest;
  final SecuredStorage _securedStorage;

  AuthRepositories({
    required RestfulRequest restfulRequest,
    required SecuredStorage securedStorage,
  })  : _restfulRequest = restfulRequest,
        _securedStorage = securedStorage;

  @override
  Future<BaseResult<UserModel>> register({
    required String name,
    required String email,
    required String password,
    BankInfoModel? bankInfo,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (bankInfo != null) 'bankInfo': bankInfo.toJson(),
    };

    final result = await _restfulRequest.post<Map<String, dynamic>>(
      AuthPath.register,
      data: payload,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      final accessToken = data['accessToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (accessToken != null && userJson != null) {
        final user = UserModel.fromJson(userJson);
        await _securedStorage.saveToken(accessToken);
        await _securedStorage.saveUser(user);
        return BaseResult.ok(user, message: result.message);
      }
    }

    return BaseResult.fail(
      result.message ?? 'Đăng ký thất bại',
      errorCode: result.errorCode,
    );
  }

  @override
  Future<BaseResult<UserModel>> login({
    required String email,
    required String password,
  }) async {
    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    final result = await _restfulRequest.post<Map<String, dynamic>>(
      AuthPath.login,
      data: payload,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      final accessToken = data['accessToken'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (accessToken != null && userJson != null) {
        final user = UserModel.fromJson(userJson);
        await _securedStorage.saveToken(accessToken);
        await _securedStorage.saveUser(user);
        return BaseResult.ok(user, message: result.message);
      }
    }

    return BaseResult.fail(
      result.message ?? 'Đăng nhập thất bại',
      errorCode: result.errorCode,
    );
  }

  @override
  Future<BaseResult<UserModel>> updateProfile({
    String? name,
    String? avatarUrl,
    BankInfoModel? bankInfo,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
      if (bankInfo != null) 'bankInfo': bankInfo.toJson(),
    };

    final result = await _restfulRequest.put<Map<String, dynamic>>(
      AuthPath.updateProfile,
      data: payload,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      final userJson = (data['user'] is Map<String, dynamic>)
          ? data['user'] as Map<String, dynamic>
          : data;

      final user = UserModel.fromJson(userJson);
      await _securedStorage.saveUser(user);
      return BaseResult.ok(user, message: result.message);
    }

    return BaseResult.fail(
      result.message ?? 'Cập nhật thông tin thất bại',
      errorCode: result.errorCode,
    );
  }
}
