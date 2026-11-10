import 'package:smartsplit_mobile/src/core/infrastructure/model/bank_info_model.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';

/// Khoản nợ tối giản sau khi chạy thuật toán Greedy (`ISimplifiedDebt` tại Mục 2.2 contract.md).
/// 
/// Hỗ trợ cả 2 trường hợp:
/// - `fromUser` / `toUser` là `String` ObjectId.
/// - `fromUser` / `toUser` là `UserModel` đã được Backend populate đầy đủ thông tin `bankInfo`.
class SimplifiedDebtModel {
  final String rawFromUser;
  final UserModel? fromUserModel;
  final String rawToUser;
  final UserModel? toUserModel;
  final int amount;

  const SimplifiedDebtModel({
    required this.rawFromUser,
    this.fromUserModel,
    required this.rawToUser,
    this.toUserModel,
    required this.amount,
  });

  factory SimplifiedDebtModel.fromJson(Map<String, dynamic> json) {
    // Xử lý fromUser
    String fromId = '';
    UserModel? fromModel;
    final rawFrom = json['fromUser'];
    if (rawFrom is Map<String, dynamic>) {
      fromModel = UserModel.fromJson(rawFrom);
      fromId = fromModel.id;
    } else if (rawFrom != null) {
      fromId = rawFrom.toString();
    }

    // Xử lý toUser
    String toId = '';
    UserModel? toModel;
    final rawTo = json['toUser'];
    if (rawTo is Map<String, dynamic>) {
      toModel = UserModel.fromJson(rawTo);
      toId = toModel.id;
    } else if (rawTo != null) {
      toId = rawTo.toString();
    }

    final rawAmount = json['amount'];
    final parsedAmount = rawAmount is num ? rawAmount.round() : 0;

    return SimplifiedDebtModel(
      rawFromUser: fromId,
      fromUserModel: fromModel,
      rawToUser: toId,
      toUserModel: toModel,
      amount: parsedAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromUser': fromUserModel != null ? fromUserModel!.toJson() : rawFromUser,
      'toUser': toUserModel != null ? toUserModel!.toJson() : rawToUser,
      'amount': amount,
    };
  }

  // --- GETTERS TIỆN ÍCH CHO VIEW ---

  /// ID người nợ (con nợ)
  String get fromUserId => fromUserModel?.id ?? rawFromUser;

  /// Tên người nợ
  String get fromUserName => fromUserModel?.name ?? 'Thành viên ($fromUserId)';

  /// ID người nhận (chủ nợ)
  String get toUserId => toUserModel?.id ?? rawToUser;

  /// Tên người nhận
  String get toUserName => toUserModel?.name ?? 'Thành viên ($toUserId)';

  /// Thông tin ngân hàng của chủ nợ phục vụ tạo mã VietQR
  BankInfoModel? get toUserBankInfo => toUserModel?.bankInfo;

  SimplifiedDebtModel copyWith({
    String? rawFromUser,
    UserModel? fromUserModel,
    String? rawToUser,
    UserModel? toUserModel,
    int? amount,
  }) {
    return SimplifiedDebtModel(
      rawFromUser: rawFromUser ?? this.rawFromUser,
      fromUserModel: fromUserModel ?? this.fromUserModel,
      rawToUser: rawToUser ?? this.rawToUser,
      toUserModel: toUserModel ?? this.toUserModel,
      amount: amount ?? this.amount,
    );
  }
}
