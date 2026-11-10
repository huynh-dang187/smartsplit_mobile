import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';
import 'parsed_receipt_model.dart';

/// Chi tiết món trong hóa đơn đã lưu vào CSDL (`IExpenseItem` tại contract.md).
class ExpenseItemModel {
  final String name;
  final double quantity;
  final int unitPrice;
  final int totalPrice;
  final List<String> assignedTo;

  const ExpenseItemModel({
    required this.name,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
    this.assignedTo = const [],
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    final rawQty = json['quantity'];
    final rawUnit = json['unitPrice'];
    final rawTotal = json['totalPrice'];

    final rawAssigned = json['assignedTo'];
    final List<String> assigned = [];
    if (rawAssigned is List) {
      for (final a in rawAssigned) {
        if (a != null) assigned.add(a.toString());
      }
    }

    return ExpenseItemModel(
      name: json['name']?.toString() ?? '',
      quantity: rawQty is num ? rawQty.toDouble() : 1.0,
      unitPrice: rawUnit is num ? rawUnit.round() : 0,
      totalPrice: rawTotal is num ? rawTotal.round() : 0,
      assignedTo: assigned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'assignedTo': assignedTo,
    };
  }
}

/// Phần tiền phân bổ chi tiết cho từng thành viên (`IMemberShare` tại contract.md).
class MemberShareModel {
  final String userId;
  final UserModel? user;
  final int baseAmount;
  final int extraAmount;
  final int finalAmount;

  const MemberShareModel({
    required this.userId,
    this.user,
    required this.baseAmount,
    required this.extraAmount,
    required this.finalAmount,
  });

  factory MemberShareModel.fromJson(Map<String, dynamic> json) {
    String uId = '';
    UserModel? uModel;
    final rawUser = json['userId'];
    if (rawUser is Map<String, dynamic>) {
      uModel = UserModel.fromJson(rawUser);
      uId = uModel.id;
    } else if (rawUser != null) {
      uId = rawUser.toString();
    }

    final rawBase = json['baseAmount'];
    final rawExtra = json['extraAmount'];
    final rawFinal = json['finalAmount'];

    return MemberShareModel(
      userId: uId,
      user: uModel,
      baseAmount: rawBase is num ? rawBase.round() : 0,
      extraAmount: rawExtra is num ? rawExtra.round() : 0,
      finalAmount: rawFinal is num ? rawFinal.round() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': user != null ? user!.toJson() : userId,
      'baseAmount': baseAmount,
      'extraAmount': extraAmount,
      'finalAmount': finalAmount,
    };
  }

  String get memberName => user?.name ?? 'Thành viên ($userId)';
}

/// Mô hình chi tiêu / hóa đơn chia tiền (`IExpense` tại Mục 2.3 contract.md).
class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final String type; // "BILL" hoặc "SETTLEMENT"
  final String paidById;
  final UserModel? paidByUser;
  final List<ExpenseItemModel> items;
  final ExtraChargesModel extraCharges;
  final List<MemberShareModel> memberShares;
  final int subtotalAmount;
  final int totalAmount;
  final DateTime? createdAt;

  const ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.type = 'BILL',
    required this.paidById,
    this.paidByUser,
    this.items = const [],
    this.extraCharges = const ExtraChargesModel(),
    this.memberShares = const [],
    required this.subtotalAmount,
    required this.totalAmount,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    // Xử lý paidBy
    String pId = '';
    UserModel? pUser;
    final rawPaidBy = json['paidBy'];
    if (rawPaidBy is Map<String, dynamic>) {
      pUser = UserModel.fromJson(rawPaidBy);
      pId = pUser.id;
    } else if (rawPaidBy != null) {
      pId = rawPaidBy.toString();
    }

    // Xử lý items
    final rawItems = json['items'];
    final List<ExpenseItemModel> itemsList = [];
    if (rawItems is List) {
      for (final i in rawItems) {
        if (i is Map<String, dynamic>) {
          itemsList.add(ExpenseItemModel.fromJson(i));
        }
      }
    }

    // Xử lý extraCharges
    final rawExtra = json['extraCharges'];
    final extra = rawExtra is Map<String, dynamic>
        ? ExtraChargesModel.fromJson(rawExtra)
        : const ExtraChargesModel();

    // Xử lý memberShares
    final rawShares = json['memberShares'];
    final List<MemberShareModel> sharesList = [];
    if (rawShares is List) {
      for (final s in rawShares) {
        if (s is Map<String, dynamic>) {
          sharesList.add(MemberShareModel.fromJson(s));
        }
      }
    }

    final rawSubtotal = json['subtotalAmount'];
    final rawTotal = json['totalAmount'];

    return ExpenseModel(
      id: id,
      groupId: json['groupId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'BILL',
      paidById: pId,
      paidByUser: pUser,
      items: itemsList,
      extraCharges: extra,
      memberShares: sharesList,
      subtotalAmount: rawSubtotal is num ? rawSubtotal.round() : 0,
      totalAmount: rawTotal is num ? rawTotal.round() : 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'groupId': groupId,
      'title': title,
      'type': type,
      'paidBy': paidByUser != null ? paidByUser!.toJson() : paidById,
      'items': items.map((i) => i.toJson()).toList(),
      'extraCharges': extraCharges.toJson(),
      'memberShares': memberShares.map((s) => s.toJson()).toList(),
      'subtotalAmount': subtotalAmount,
      'totalAmount': totalAmount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Là hóa đơn thanh toán / trả nợ
  bool get isSettlement => type == 'SETTLEMENT';

  /// Là hóa đơn ăn uống thông thường
  bool get isBill => type == 'BILL';

  /// Tên người trả tiền
  String get paidByName => paidByUser?.name ?? 'Thành viên ($paidById)';

  /// Lấy phần tiền của một user cụ thể trong bill này
  MemberShareModel? getShareForUser(String userId) {
    try {
      return memberShares.firstWhere((s) => s.userId == userId);
    } catch (_) {
      return null;
    }
  }

  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? type,
    String? paidById,
    UserModel? paidByUser,
    List<ExpenseItemModel>? items,
    ExtraChargesModel? extraCharges,
    List<MemberShareModel>? memberShares,
    int? subtotalAmount,
    int? totalAmount,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      type: type ?? this.type,
      paidById: paidById ?? this.paidById,
      paidByUser: paidByUser ?? this.paidByUser,
      items: items ?? this.items,
      extraCharges: extraCharges ?? this.extraCharges,
      memberShares: memberShares ?? this.memberShares,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
