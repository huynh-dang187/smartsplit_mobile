import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';
import 'group_member_model.dart';
import 'simplified_debt_model.dart';

/// Mô hình nhóm chia tiền (`IGroup` tại Mục 2.2 contract.md).
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String createdById;
  final UserModel? createdByUser;
  final List<GroupMemberModel> members;
  final List<SimplifiedDebtModel> simplifiedDebts;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdById,
    this.createdByUser,
    this.members = const [],
    this.simplifiedDebts = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    // Xử lý id
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    // Xử lý createdBy
    String creatorId = '';
    UserModel? creatorModel;
    final rawCreator = json['createdBy'];
    if (rawCreator is Map<String, dynamic>) {
      creatorModel = UserModel.fromJson(rawCreator);
      creatorId = creatorModel.id;
    } else if (rawCreator != null) {
      creatorId = rawCreator.toString();
    }

    // Xử lý members
    final rawMembers = json['members'];
    final List<GroupMemberModel> membersList = [];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is Map<String, dynamic>) {
          membersList.add(GroupMemberModel.fromJson(item));
        }
      }
    }

    // Xử lý simplifiedDebts
    final rawDebts = json['simplifiedDebts'];
    final List<SimplifiedDebtModel> debtsList = [];
    if (rawDebts is List) {
      for (final item in rawDebts) {
        if (item is Map<String, dynamic>) {
          debtsList.add(SimplifiedDebtModel.fromJson(item));
        }
      }
    }

    return GroupModel(
      id: id,
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      createdById: creatorId,
      createdByUser: creatorModel,
      members: membersList,
      simplifiedDebts: debtsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      if (description != null) 'description': description,
      'createdBy': createdByUser != null ? createdByUser!.toJson() : createdById,
      'members': members.map((m) => m.toJson()).toList(),
      'simplifiedDebts': simplifiedDebts.map((d) => d.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // --- GETTERS & TIỆN ÍCH NGHIỆP VỤ ---

  /// Số lượng thành viên nhóm
  int get totalMembers => members.length;

  /// Lấy số dư của một user cụ thể trong nhóm
  int getUserNetBalance(String userId) {
    try {
      final member = members.firstWhere((m) => m.memberId == userId);
      return member.netBalance;
    } catch (_) {
      return 0;
    }
  }

  /// Tìm thành viên theo userId
  GroupMemberModel? findMember(String userId) {
    try {
      return members.firstWhere((m) => m.memberId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Lấy danh sách các khoản nợ liên quan đến một user cụ thể
  List<SimplifiedDebtModel> getDebtsForUser(String userId) {
    return simplifiedDebts
        .where((debt) => debt.fromUserId == userId || debt.toUserId == userId)
        .toList();
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdById,
    UserModel? createdByUser,
    List<GroupMemberModel>? members,
    List<SimplifiedDebtModel>? simplifiedDebts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      createdByUser: createdByUser ?? this.createdByUser,
      members: members ?? this.members,
      simplifiedDebts: simplifiedDebts ?? this.simplifiedDebts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
