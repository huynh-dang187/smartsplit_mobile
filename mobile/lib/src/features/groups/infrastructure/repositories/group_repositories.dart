import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/datasources/network/api/restful_request.dart';
import '../../domain/interfaces/i_group_repositories.dart';
import '../models/group_detail_response_model.dart';
import '../models/group_model.dart';
import '../paths/group_path.dart';

/// Triển khai thực tế các API quản lý nhóm và cân bằng nợ.
class GroupRepositories implements IGroupRepositories {
  final RestfulRequest _restfulRequest;

  GroupRepositories({
    required RestfulRequest restfulRequest,
  }) : _restfulRequest = restfulRequest;

  @override
  Future<BaseResult<GroupModel>> createGroup({
    required String name,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    final result = await _restfulRequest.post<Map<String, dynamic>>(
      GroupPath.groups,
      data: payload,
    );

    if (result.isSuccess && result.data != null) {
      final rawGroup = result.data!['group'];
      if (rawGroup is Map<String, dynamic>) {
        return BaseResult.ok(
          GroupModel.fromJson(rawGroup),
          message: result.message,
        );
      }
    }

    return BaseResult.fail(
      result.message ?? 'Tạo nhóm thất bại',
      errorCode: result.errorCode,
    );
  }

  @override
  Future<BaseResult<List<GroupModel>>> getMyGroups() async {
    final result = await _restfulRequest.get<Map<String, dynamic>>(
      GroupPath.groups,
    );

    if (result.isSuccess && result.data != null) {
      final rawGroups = result.data!['groups'];
      if (rawGroups is List) {
        final groups = rawGroups
            .whereType<Map<String, dynamic>>()
            .map((g) => GroupModel.fromJson(g))
            .toList();
        return BaseResult.ok(groups, message: result.message);
      }
    }

    return BaseResult.fail(
      result.message ?? 'Lấy danh sách nhóm thất bại',
      errorCode: result.errorCode,
    );
  }

  @override
  Future<BaseResult<GroupDetailResponseModel>> getGroupDetail(String groupId) async {
    final result = await _restfulRequest.get<Map<String, dynamic>>(
      GroupPath.groupDetail(groupId),
    );

    if (result.isSuccess && result.data != null) {
      return BaseResult.ok(
        GroupDetailResponseModel.fromJson(result.data!),
        message: result.message,
      );
    }

    return BaseResult.fail(
      result.message ?? 'Lấy chi tiết nhóm thất bại',
      errorCode: result.errorCode,
    );
  }

  @override
  Future<BaseResult<GroupModel>> addMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),
    };

    final result = await _restfulRequest.post<Map<String, dynamic>>(
      GroupPath.addMember(groupId),
      data: payload,
    );

    if (result.isSuccess && result.data != null) {
      final rawGroup = result.data!['group'];
      if (rawGroup is Map<String, dynamic>) {
        return BaseResult.ok(
          GroupModel.fromJson(rawGroup),
          message: result.message,
        );
      }
    }

    return BaseResult.fail(
      result.message ?? 'Thêm thành viên thất bại',
      errorCode: result.errorCode,
    );
  }

  @override
  Future<BaseResult<GroupModel>> settleDebt({
    required String groupId,
    required String fromUser,
    required String toUser,
    required int amount,
  }) async {
    final payload = <String, dynamic>{
      'fromUser': fromUser,
      'toUser': toUser,
      'amount': amount,
    };

    final result = await _restfulRequest.post<Map<String, dynamic>>(
      GroupPath.settleUp(groupId),
      data: payload,
    );

    if (result.isSuccess && result.data != null) {
      final rawGroup = result.data!['group'];
      if (rawGroup is Map<String, dynamic>) {
        return BaseResult.ok(
          GroupModel.fromJson(rawGroup),
          message: result.message,
        );
      }
    }

    return BaseResult.fail(
      result.message ?? 'Thanh toán nợ thất bại',
      errorCode: result.errorCode,
    );
  }
}
