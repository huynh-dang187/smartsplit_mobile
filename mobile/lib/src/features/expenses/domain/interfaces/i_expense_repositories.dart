import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import '../../infrastructure/models/create_expense_payload.dart';
import '../../infrastructure/models/expense_model.dart';
import '../../infrastructure/models/parsed_receipt_model.dart';

/// Hợp đồng Interface định nghĩa các nghiệp vụ quét hóa đơn AI và tạo khoản chi tiêu.
abstract interface class IExpenseRepositories {
  /// Bóc tách hóa đơn bằng Gemini Vision AI từ đường dẫn tệp ảnh cục bộ
  Future<BaseResult<ParsedReceiptModel>> scanReceipt(String imagePath);

  /// Tạo và lưu hóa đơn chi tiêu (phân bổ Pro-rata và tính toán nợ tối giản trên server)
  Future<BaseResult<ExpenseModel>> createExpense({
    required String groupId,
    required CreateExpensePayload payload,
  });
}
