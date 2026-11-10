import 'package:smartsplit_mobile/src/core/infrastructure/model/bank_info_model.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';

/// Thành viên trong nhóm kèm số dư ròng `netBalance`.
/// 
/// Xử lý linh hoạt trường `userId`:
/// - Có thể là `String` ID khi unpopulated (danh sách tóm tắt hoặc mới tạo).
/// - Hoặc là đối tượng `UserModel` đã được `.populate('name email avatarUrl bankInfo')` khi gọi chi tiết nhóm.
class GroupMemberModel {
  final String rawUserId;
  final UserModel? user;
  final int netBalance;

  const GroupMemberModel({
    required this.rawUserId,
    this.user,
    this.netBalance = 0,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    final rawUserField = json['userId'];
    String parsedUserId = '';
    UserModel? parsedUser;

    if (rawUserField is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(rawUserField);
      parsedUserId = parsedUser.id;
    } else if (rawUserField != null) {
      parsedUserId = rawUserField.toString();
    }

    final rawBalance = json['netBalance'];
    final parsedBalance = rawBalance is num ? rawBalance.round() : 0;

    return GroupMemberModel(
      rawUserId: parsedUserId,
      user: parsedUser,
      netBalance: parsedBalance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': user != null ? user!.toJson() : rawUserId,
      'netBalance': netBalance,
    };
  }

  /// ID định danh của thành viên
  String get memberId => user?.id ?? rawUserId;

  /// Tên hiển thị của thành viên (hoặc fallback về ID nếu chưa populate)
  String get memberName => user?.name ?? (memberId.isNotEmpty ? 'Thành viên ($memberId)' : 'Thành viên');

  /// Email của thành viên
  String? get memberEmail => user?.email;

  /// Ảnh đại diện
  String? get memberAvatarUrl => user?.avatarUrl;

  /// Thông tin ngân hàng nhận tiền
  BankInfoModel? get memberBankInfo => user?.bankInfo;

  /// Đã có thông tin chi tiết user chưa
  bool get isPopulated => user != null;

  GroupMemberModel copyWith({
    String? rawUserId,
    UserModel? user,
    int? netBalance,
  }) {
    return GroupMemberModel(
      rawUserId: rawUserId ?? this.rawUserId,
      user: user ?? this.user,
      netBalance: netBalance ?? this.netBalance,
    );
  }
}
