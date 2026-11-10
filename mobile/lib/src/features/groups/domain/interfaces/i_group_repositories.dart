import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import '../../infrastructure/models/group_detail_response_model.dart';
import '../../infrastructure/models/group_model.dart';

/// Hợp đồng Interface định nghĩa các nghiệp vụ quản lý nhóm và số dư nợ.
abstract interface class IGroupRepositories {
  /// Tạo nhóm mới
  Future<BaseResult<GroupModel>> createGroup({
    required String name,
    String? description,
  });

  /// Lấy danh sách toàn bộ các nhóm mà user hiện tại tham gia
  Future<BaseResult<List<GroupModel>>> getMyGroups();

  /// Lấy chi tiết nhóm (gồm thành viên populated bankInfo, danh sách nợ rút gọn và lịch sử hóa đơn)
  Future<BaseResult<GroupDetailResponseModel>> getGroupDetail(String groupId);

  /// Mời thành viên vào nhóm qua email
  Future<BaseResult<GroupModel>> addMemberByEmail({
    required String groupId,
    required String email,
  });

  /// Xác nhận trả nợ giữa 2 thành viên (Settle Up)
  Future<BaseResult<GroupModel>> settleDebt({
    required String groupId,
    required String fromUser,
    required String toUser,
    required int amount,
  });
}
