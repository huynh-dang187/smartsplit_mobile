/// Chi tiết món bóc tách từ hóa đơn bằng Gemini Vision AI.
class ParsedReceiptItemModel {
  final String id;
  final String name;
  final double quantity;
  final int unitPrice;
  final int totalPrice;
  final List<String> assignedTo;

  const ParsedReceiptItemModel({
    required this.id,
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.assignedTo = const [],
  });

  factory ParsedReceiptItemModel.fromJson(Map<String, dynamic> json, [int index = 0]) {
    final rawQty = json['quantity'];
    final double qty = rawQty is num ? rawQty.toDouble() : 1.0;

    final rawUnitPrice = json['unitPrice'];
    final int uPrice = rawUnitPrice is num ? rawUnitPrice.round() : 0;

    final rawTotalPrice = json['totalPrice'];
    final int tPrice = rawTotalPrice is num ? rawTotalPrice.round() : (qty * uPrice).round();

    final rawAssigned = json['assignedTo'];
    final List<String> assignedList = [];
    if (rawAssigned is List) {
      for (final id in rawAssigned) {
        if (id != null) assignedList.add(id.toString());
      }
    }

    return ParsedReceiptItemModel(
      id: json['id']?.toString() ?? 'item_$index',
      name: json['name']?.toString() ?? '',
      quantity: qty,
      unitPrice: uPrice,
      totalPrice: tPrice,
      assignedTo: assignedList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'assignedTo': assignedTo,
    };
  }

  ParsedReceiptItemModel copyWith({
    String? id,
    String? name,
    double? quantity,
    int? unitPrice,
    int? totalPrice,
    List<String>? assignedTo,
  }) {
    return ParsedReceiptItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}

/// Phụ phí trên hóa đơn (Thuế VAT, Phí dịch vụ, Giảm giá).
class ExtraChargesModel {
  final int tax;
  final int serviceCharge;
  final int discount;

  const ExtraChargesModel({
    this.tax = 0,
    this.serviceCharge = 0,
    this.discount = 0,
  });

  factory ExtraChargesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ExtraChargesModel();

    final t = json['tax'];
    final sc = json['serviceCharge'];
    final d = json['discount'];

    return ExtraChargesModel(
      tax: t is num ? t.round() : 0,
      serviceCharge: sc is num ? sc.round() : 0,
      discount: d is num ? d.round() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tax': tax,
      'serviceCharge': serviceCharge,
      'discount': discount,
    };
  }

  /// Phụ phí ròng: Thuế + Phí - Giảm giá
  int get netExtra => tax + serviceCharge - discount;

  ExtraChargesModel copyWith({
    int? tax,
    int? serviceCharge,
    int? discount,
  }) {
    return ExtraChargesModel(
      tax: tax ?? this.tax,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      discount: discount ?? this.discount,
    );
  }
}

/// Toàn bộ kết quả hóa đơn bóc tách bởi Gemini Vision AI (`ParsedReceiptSchema`).
class ParsedReceiptModel {
  final List<ParsedReceiptItemModel> items;
  final ExtraChargesModel extraCharges;
  final int subtotalAmount;
  final int totalAmount;
  final int calculatedTotal;
  final bool isDiscrepancy;

  const ParsedReceiptModel({
    this.items = const [],
    this.extraCharges = const ExtraChargesModel(),
    required this.subtotalAmount,
    required this.totalAmount,
    required this.calculatedTotal,
    this.isDiscrepancy = false,
  });

  factory ParsedReceiptModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<ParsedReceiptItemModel> itemsList = [];
    if (rawItems is List) {
      for (int i = 0; i < rawItems.length; i++) {
        final item = rawItems[i];
        if (item is Map<String, dynamic>) {
          itemsList.add(ParsedReceiptItemModel.fromJson(item, i));
        }
      }
    }

    final rawExtra = json['extraCharges'];
    final extraCharges = rawExtra is Map<String, dynamic>
        ? ExtraChargesModel.fromJson(rawExtra)
        : const ExtraChargesModel();

    final rawSubtotal = json['subtotalAmount'];
    final rawTotal = json['totalAmount'];
    final rawCalc = json['calculatedTotal'];

    final subtotal = rawSubtotal is num ? rawSubtotal.round() : 0;
    final total = rawTotal is num ? rawTotal.round() : 0;
    final calc = rawCalc is num ? rawCalc.round() : (subtotal + extraCharges.netExtra);

    return ParsedReceiptModel(
      items: itemsList,
      extraCharges: extraCharges,
      subtotalAmount: subtotal,
      totalAmount: total,
      calculatedTotal: calc,
      isDiscrepancy: json['isDiscrepancy'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'extraCharges': extraCharges.toJson(),
      'subtotalAmount': subtotalAmount,
      'totalAmount': totalAmount,
      'calculatedTotal': calculatedTotal,
      'isDiscrepancy': isDiscrepancy,
    };
  }

  /// Tổng tiền các món thực tế
  int get computedItemsSum => items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Tổng tiền tính lại kèm phụ phí ròng
  int get computedTotalWithExtras => computedItemsSum + extraCharges.netExtra;

  ParsedReceiptModel copyWith({
    List<ParsedReceiptItemModel>? items,
    ExtraChargesModel? extraCharges,
    int? subtotalAmount,
    int? totalAmount,
    int? calculatedTotal,
    bool? isDiscrepancy,
  }) {
    return ParsedReceiptModel(
      items: items ?? this.items,
      extraCharges: extraCharges ?? this.extraCharges,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      calculatedTotal: calculatedTotal ?? this.calculatedTotal,
      isDiscrepancy: isDiscrepancy ?? this.isDiscrepancy,
    );
  }
}
