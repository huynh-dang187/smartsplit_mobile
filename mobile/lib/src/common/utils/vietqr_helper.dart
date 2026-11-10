/// Tiện ích sinh URL ảnh mã VietQR theo chuẩn Napas quy định tại Mục 6 contract.md.
abstract class VietQrHelper {
  /// Base template sinh ảnh VietQR chuẩn compact2
  static const String _vietQrBaseUrl = 'https://img.vietqr.io/image';

  /// Sinh đường dẫn ảnh mã VietQR trực tuyến.
  /// 
  /// Format:
  /// `https://img.vietqr.io/image/{bankBin}-{accountNo}-compact2.png?amount={amount}&addInfo={encodedMessage}&accountName={encodedAccountName}`
  /// 
  /// - [bankBin]: Mã BIN ngân hàng theo chuẩn Napas (VD: "970436" - Vietcombank)
  /// - [accountNo]: Số tài khoản ngân hàng thụ hưởng
  /// - [amount]: Số tiền cần chuyển (số nguyên VNĐ)
  /// - [accountName]: Tên chủ tài khoản (VD: "NGUYEN VAN A")
  /// - [addInfo]: Nội dung chuyển khoản (mặc định nếu null: "SmartSplit {fromUserName} thanh toan {groupName}")
  static String generateQrUrl({
    required String bankBin,
    required String accountNo,
    required int amount,
    required String accountName,
    String? addInfo,
    String? fromUserName,
    String? groupName,
  }) {
    final cleanBin = bankBin.trim();
    final cleanAccountNo = accountNo.trim();
    final cleanAccountName = accountName.trim().toUpperCase();

    // Nội dung mặc định theo contract.md: "SmartSplit {fromUserName} thanh toan {groupName}"
    final message = addInfo ??
        (fromUserName != null && groupName != null
            ? 'SmartSplit $fromUserName thanh toan $groupName'
            : 'SmartSplit thanh toan');

    final encodedMessage = Uri.encodeComponent(message);
    final encodedAccountName = Uri.encodeComponent(cleanAccountName);

    return '$_vietQrBaseUrl/$cleanBin-$cleanAccountNo-compact2.png'
        '?amount=$amount'
        '&addInfo=$encodedMessage'
        '&accountName=$encodedAccountName';
  }
}
