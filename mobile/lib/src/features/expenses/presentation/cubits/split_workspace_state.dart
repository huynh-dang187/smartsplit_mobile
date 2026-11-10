part of 'split_workspace_cubit.dart';

/// Trạng thái của không gian làm việc chia tiền hóa đơn (SplitWorkspace).
final class SplitWorkspaceState {
  final BlocStatus status;
  final String title;
  final String paidByUserId;
  final List<ParsedReceiptItemModel> items;
  final Map<String, List<String>> itemAssignments; // itemId -> list of userIds
  final ExtraChargesModel extraCharges;
  final int receiptTotalAmount; // Tổng tiền in trên bill đọc từ AI
  final String? errorMessage;

  const SplitWorkspaceState({
    this.status = BlocStatus.init,
    this.title = 'Hóa đơn mới',
    this.paidByUserId = '',
    this.items = const [],
    this.itemAssignments = const {},
    this.extraCharges = const ExtraChargesModel(),
    this.receiptTotalAmount = 0,
    this.errorMessage,
  });

  // --- CÁC GETTERS TÍNH TOÁN REALTIME THEO CONTRACT.MD MỤC 4.1 ---

  /// Tổng tiền món gốc: S = sum(item.totalPrice)
  int get subtotalAmount {
    int sum = 0;
    for (final item in items) {
      sum += item.totalPrice;
    }
    return sum;
  }

  /// Phụ phí ròng: E = tax + serviceCharge - discount
  int get netExtraCharges => extraCharges.netExtra;

  /// Tổng thực trả tính toán: calculatedTotal = S + E
  int get calculatedTotal {
    final total = subtotalAmount + netExtraCharges;
    return total > 0 ? total : 0;
  }

  /// Cảnh báo chênh lệch: true nếu AI đọc được tổng tiền trên bill khác với calculatedTotal
  bool get isDiscrepancy {
    if (receiptTotalAmount <= 0) return false;
    return calculatedTotal != receiptTotalAmount;
  }

  /// Hóa đơn có hợp lệ để bấm "Lưu & Chia tiền" hay không:
  /// - Phải có ít nhất 1 món
  /// - calculatedTotal > 0
  /// - Mỗi món phải có ít nhất 1 người ăn (assignedTo.isNotEmpty)
  bool get isValidToSubmit {
    if (items.isEmpty) return false;
    if (calculatedTotal <= 0) return false;
    if (paidByUserId.isEmpty) return false;

    for (final item in items) {
      final assigned = itemAssignments[item.id] ?? item.assignedTo;
      if (assigned.isEmpty) return false;
    }
    return true;
  }

  /// Thuật toán Pro-rata tính toán realtime số tiền từng thành viên phải trả (F_u).
  ///
  /// Bám sát chính xác công thức tại Mục 4.1 contract.md:
  /// 1. Với mỗi người u, tính B_u = sum(item.totalPrice / k)
  /// 2. Phụ phí E_u = Math.round(E * (B_u / S))
  /// 3. F_u = Math.round(B_u) + E_u
  /// 4. Sai số làm tròn Delta = T - sum(F_u) được cộng dồn vào paidByUserId
  Map<String, int> get realtimeMemberShares {
    final Map<String, int> result = {};
    if (items.isEmpty || subtotalAmount <= 0) return result;

    final S = subtotalAmount;
    final E = netExtraCharges;
    final T = calculatedTotal;

    // 1. Tính B_u (tiền món gốc của từng người)
    final Map<String, double> baseShares = {};
    for (final item in items) {
      final assigned = itemAssignments[item.id] ?? item.assignedTo;
      if (assigned.isEmpty) continue;
      final sharePerPerson = item.totalPrice / assigned.length;
      for (final userId in assigned) {
        baseShares[userId] = (baseShares[userId] ?? 0.0) + sharePerPerson;
      }
    }

    // 2 & 3. Tính E_u và F_u cho từng người
    int sumFu = 0;
    for (final entry in baseShares.entries) {
      final userId = entry.key;
      final bu = entry.value;

      final double proRataRatio = S > 0 ? (bu / S) : 0.0;
      final int eu = (E * proRataRatio).round();
      final int fu = bu.round() + eu;

      result[userId] = fu;
      sumFu += fu;
    }

    // 4. Bù sai số Delta vào người trả tiền (paidByUserId)
    final int delta = T - sumFu;
    if (delta != 0 && paidByUserId.isNotEmpty) {
      result[paidByUserId] = (result[paidByUserId] ?? 0) + delta;
    }

    return result;
  }

  SplitWorkspaceState copyWith({
    BlocStatus? status,
    String? title,
    String? paidByUserId,
    List<ParsedReceiptItemModel>? items,
    Map<String, List<String>>? itemAssignments,
    ExtraChargesModel? extraCharges,
    int? receiptTotalAmount,
    String? errorMessage,
  }) {
    return SplitWorkspaceState(
      status: status ?? this.status,
      title: title ?? this.title,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      items: items ?? this.items,
      itemAssignments: itemAssignments ?? this.itemAssignments,
      extraCharges: extraCharges ?? this.extraCharges,
      receiptTotalAmount: receiptTotalAmount ?? this.receiptTotalAmount,
      errorMessage: errorMessage,
    );
  }
}
