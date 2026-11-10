import 'package:dio/dio.dart';
import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/datasources/network/api/restful_request.dart';
import '../../domain/interfaces/i_expense_repositories.dart';
import '../models/create_expense_payload.dart';
import '../models/expense_model.dart';
import '../models/parsed_receipt_model.dart';
import '../paths/expense_path.dart';

/// Triển khai thực tế các API quét hóa đơn AI và tạo khoản chi tiêu.
class ExpenseRepositories implements IExpenseRepositories {
  final RestfulRequest _restfulRequest;

  ExpenseRepositories({
    required RestfulRequest restfulRequest,
  }) : _restfulRequest = restfulRequest;

  @override
  Future<BaseResult<ParsedReceiptModel>> scanReceipt(String imagePath) async {
    try {
      final file = await MultipartFile.fromFile(imagePath);
      final formData = FormData.fromMap({
        'receipt': file,
      });

      final result = await _restfulRequest.postMultipart<Map<String, dynamic>>(
        ExpensePath.scanReceipt,
        formData: formData,
      );

      if (result.isSuccess && result.data != null) {
        return BaseResult.ok(
          ParsedReceiptModel.fromJson(result.data!),
          message: result.message,
        );
      }

      return BaseResult.fail(
        result.message ?? 'Quét hóa đơn thất bại',
        errorCode: result.errorCode,
      );
    } catch (e) {
      return BaseResult.fail(
        'Không thể mở tệp hình ảnh hóa đơn: ${e.toString()}',
        errorCode: 'FILE_READ_ERROR',
      );
    }
  }

  @override
  Future<BaseResult<ExpenseModel>> createExpense({
    required String groupId,
    required CreateExpensePayload payload,
  }) async {
    final result = await _restfulRequest.post<Map<String, dynamic>>(
      ExpensePath.createExpense(groupId),
      data: payload.toJson(),
    );

    if (result.isSuccess && result.data != null) {
      final rawExpense = result.data!['expense'];
      if (rawExpense is Map<String, dynamic>) {
        return BaseResult.ok(
          ExpenseModel.fromJson(rawExpense),
          message: result.message,
        );
      }
    }

    return BaseResult.fail(
      result.message ?? 'Tạo hóa đơn thất bại',
      errorCode: result.errorCode,
    );
  }
}
