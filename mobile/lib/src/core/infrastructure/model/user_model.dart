import 'bank_info_model.dart';

/// DTO thông tin người dùng trong hệ thống SmartSplit.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final BankInfoModel? bankInfo;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bankInfo,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bankInfo: json['bankInfo'] != null && json['bankInfo'] is Map<String, dynamic>
          ? BankInfoModel.fromJson(json['bankInfo'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bankInfo != null) 'bankInfo': bankInfo!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    BankInfoModel? bankInfo,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bankInfo: bankInfo ?? this.bankInfo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Kiểm tra user đã cấu hình tài khoản ngân hàng để nhận tiền chưa
  bool get hasBankInfo => bankInfo != null && bankInfo!.isComplete;
}
