import 'parsed_receipt_model.dart';

/// Item trong payload tạo hóa đơn chi tiêu gửi lên Backend (`POST /api/groups/:groupId/expenses`).
class CreateExpensePayloadItem {
  final String name;
  final double quantity;
  final int unitPrice;
  final int totalPrice;
  final List<String> assignedTo;

  const CreateExpensePayloadItem({
    required this.name,
    this.quantity = 1.0,
    required this.unitPrice,
    required this.totalPrice,
    required this.assignedTo,
  });

  factory CreateExpensePayloadItem.fromParsedItem(ParsedReceiptItemModel item) {
    return CreateExpensePayloadItem(
      name: item.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
      assignedTo: List<String>.from(item.assignedTo),
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

/// Dữ liệu gửi lên server khi tạo hóa đơn chi tiêu theo chuẩn Mục 3.2 contract.md.
class CreateExpensePayload {
  final String title;
  final String paidBy; // UserId người thanh toán
  final List<CreateExpensePayloadItem> items;
  final ExtraChargesModel extraCharges;
  final int totalAmount;

  const CreateExpensePayload({
    required this.title,
    required this.paidBy,
    required this.items,
    this.extraCharges = const ExtraChargesModel(),
    required this.totalAmount,
  });

  /// Tạo Payload trực tiếp từ kết quả quét hóa đơn AI Gemini
  factory CreateExpensePayload.fromParsedReceipt({
    required String title,
    required String paidBy,
    required ParsedReceiptModel receipt,
  }) {
    return CreateExpensePayload(
      title: title,
      paidBy: paidBy,
      items: receipt.items
          .map((i) => CreateExpensePayloadItem.fromParsedItem(i))
          .toList(),
      extraCharges: receipt.extraCharges,
      totalAmount: receipt.totalAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'paidBy': paidBy,
      'items': items.map((i) => i.toJson()).toList(),
      'extraCharges': extraCharges.toJson(),
      'totalAmount': totalAmount,
    };
  }

  CreateExpensePayload copyWith({
    String? title,
    String? paidBy,
    List<CreateExpensePayloadItem>? items,
    ExtraChargesModel? extraCharges,
    int? totalAmount,
  }) {
    return CreateExpensePayload(
      title: title ?? this.title,
      paidBy: paidBy ?? this.paidBy,
      items: items ?? this.items,
      extraCharges: extraCharges ?? this.extraCharges,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
