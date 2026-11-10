/// Thực thể định danh thông tin mã BIN ngân hàng Napas tại Việt Nam.
class BankBinItem {
  final String bin;
  final String shortName;
  final String name;

  const BankBinItem({
    required this.bin,
    required this.shortName,
    required this.name,
  });
}

/// Alias thuận tiện cho lựa chọn ngân hàng trong form
typedef BankOption = BankBinItem;

/// Danh sách 10 ngân hàng phổ biến theo chuẩn Napas phục vụ thanh toán VietQR trong SmartSplit.
abstract class BankBins {
  static const List<BankBinItem> supportedBanks = [
    BankBinItem(
      bin: '970436',
      shortName: 'VCB',
      name: 'Ngân hàng TMCP Ngoại thương Việt Nam (Vietcombank)',
    ),
    BankBinItem(
      bin: '970422',
      shortName: 'MB',
      name: 'Ngân hàng TMCP Quân đội (MBBank)',
    ),
    BankBinItem(
      bin: '970407',
      shortName: 'TCB',
      name: 'Ngân hàng TMCP Kỹ thương Việt Nam (Techcombank)',
    ),
    BankBinItem(
      bin: '970418',
      shortName: 'BIDV',
      name: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam (BIDV)',
    ),
    BankBinItem(
      bin: '970415',
      shortName: 'CTG',
      name: 'Ngân hàng TMCP Công thương Việt Nam (VietinBank)',
    ),
    BankBinItem(
      bin: '970416',
      shortName: 'ACB',
      name: 'Ngân hàng TMCP Á Châu (ACB)',
    ),
    BankBinItem(
      bin: '970432',
      shortName: 'VPB',
      name: 'Ngân hàng TMCP Việt Nam Thịnh Vượng (VPBank)',
    ),
    BankBinItem(
      bin: '970423',
      shortName: 'TPB',
      name: 'Ngân hàng TMCP Tiên Phong (TPBank)',
    ),
    BankBinItem(
      bin: '970403',
      shortName: 'STB',
      name: 'Ngân hàng TMCP Sài Gòn Thương Tín (Sacombank)',
    ),
    BankBinItem(
      bin: '970441',
      shortName: 'VIB',
      name: 'Ngân hàng TMCP Quốc tế Việt Nam (VIB)',
    ),
  ];

  /// Danh sách ngân hàng phổ biến (alias)
  static const List<BankBinItem> popularVietnameseBanks = supportedBanks;

  /// Tìm kiếm ngân hàng theo mã BIN
  static BankBinItem? findByBin(String bin) {
    try {
      return supportedBanks.firstWhere((b) => b.bin == bin);
    } catch (_) {
      return null;
    }
  }

  /// Tìm kiếm ngân hàng theo tên viết tắt (shortName)
  static BankBinItem? findByShortName(String shortName) {
    try {
      return supportedBanks.firstWhere(
        (b) => b.shortName.toUpperCase() == shortName.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Danh sách 10 ngân hàng Napas phổ biến tại Việt Nam (top-level constant)
const List<BankBinItem> popularVietnameseBanks = BankBins.supportedBanks;
