/// DTO thông tin tài khoản ngân hàng thụ hưởng theo chuẩn Napas / VietQR.
class BankInfoModel {
  final String bankBin;
  final String bankShortName;
  final String accountNo;
  final String accountName;

  const BankInfoModel({
    required this.bankBin,
    required this.bankShortName,
    required this.accountNo,
    required this.accountName,
  });

  factory BankInfoModel.fromJson(Map<String, dynamic> json) {
    return BankInfoModel(
      bankBin: json['bankBin']?.toString() ?? '',
      bankShortName: json['bankShortName']?.toString() ?? '',
      accountNo: json['accountNo']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankBin': bankBin,
      'bankShortName': bankShortName,
      'accountNo': accountNo,
      'accountName': accountName,
    };
  }

  BankInfoModel copyWith({
    String? bankBin,
    String? bankShortName,
    String? accountNo,
    String? accountName,
  }) {
    return BankInfoModel(
      bankBin: bankBin ?? this.bankBin,
      bankShortName: bankShortName ?? this.bankShortName,
      accountNo: accountNo ?? this.accountNo,
      accountName: accountName ?? this.accountName,
    );
  }

  /// Kiểm tra thông tin ngân hàng đã được điền đầy đủ để tạo mã VietQR chưa
  bool get isComplete =>
      bankBin.isNotEmpty &&
      bankShortName.isNotEmpty &&
      accountNo.isNotEmpty &&
      accountName.isNotEmpty;
}
