import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/features/expenses/domain/interfaces/i_expense_repositories.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/create_expense_payload.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/parsed_receipt_model.dart';

part 'split_workspace_state.dart';

/// Cubit quản lý không gian làm việc chia tiền hóa đơn thông minh (Split Workspace).
class SplitWorkspaceCubit extends Cubit<SplitWorkspaceState> {
  final IExpenseRepositories _expenseRepositories;

  SplitWorkspaceCubit({
    required IExpenseRepositories expenseRepositories,
  })  : _expenseRepositories = expenseRepositories,
        super(const SplitWorkspaceState());

  /// Bóc tách hóa đơn tự động qua Gemini Vision AI
  Future<void> scanReceiptImage(
    String imagePath,
    List<String> allMemberIds, {
    String? currentUserId,
    Function(String error)? onError,
  }) async {
    emit(state.copyWith(status: BlocStatus.loading, errorMessage: null));

    final result = await _expenseRepositories.scanReceipt(imagePath);

    if (isClosed) return;

    if (result.isSuccess && result.data != null) {
      final receipt = result.data!;
      // Mặc định gán toàn bộ thành viên trong nhóm vào mọi món ăn
      final Map<String, List<String>> initialAssignments = {};
      for (final item in receipt.items) {
        initialAssignments[item.id] = List<String>.from(allMemberIds);
      }

      emit(state.copyWith(
        status: BlocStatus.hasData,
        title: 'Hóa đơn ăn uống',
        paidByUserId: currentUserId ?? (allMemberIds.isNotEmpty ? allMemberIds.first : ''),
        items: receipt.items,
        itemAssignments: initialAssignments,
        extraCharges: receipt.extraCharges,
        receiptTotalAmount: receipt.totalAmount,
      ));
    } else {
      final errorMsg = result.message ?? 'Không thể bóc tách hóa đơn';
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: errorMsg,
      ));
      onError?.call(errorMsg);
    }
  }

  /// Khởi tạo hóa đơn nhập tay nếu người dùng không chụp ảnh
  void initManualBill(List<String> allMemberIds, String currentUserId) {
    const defaultItemId = 'item_manual_1';
    final initialItem = ParsedReceiptItemModel(
      id: defaultItemId,
      name: 'Món ăn 1',
      quantity: 1,
      unitPrice: 50000,
      totalPrice: 50000,
      assignedTo: List<String>.from(allMemberIds),
    );

    emit(state.copyWith(
      status: BlocStatus.hasData,
      title: 'Hóa đơn ăn uống',
      paidByUserId: currentUserId,
      items: [initialItem],
      itemAssignments: {
        defaultItemId: List<String>.from(allMemberIds),
      },
      extraCharges: const ExtraChargesModel(),
      receiptTotalAmount: 50000,
    ));
  }

  /// Cập nhật tên hóa đơn
  void updateTitle(String newTitle) {
    emit(state.copyWith(title: newTitle.trim().isNotEmpty ? newTitle.trim() : 'Hóa đơn mới'));
  }

  /// Thay đổi người ứng tiền thanh toán hóa đơn
  void changePayer(String userId) {
    HapticFeedback.selectionClick();
    emit(state.copyWith(paidByUserId: userId));
  }

  /// Bật/tắt gán thành viên vào một món ăn cụ thể
  void toggleMemberForItem(String itemId, String userId) {
    HapticFeedback.selectionClick();

    final currentMap = Map<String, List<String>>.from(state.itemAssignments);
    final assignedList = List<String>.from(currentMap[itemId] ?? []);

    if (assignedList.contains(userId)) {
      assignedList.remove(userId);
    } else {
      assignedList.add(userId);
    }

    currentMap[itemId] = assignedList;
    emit(state.copyWith(itemAssignments: currentMap));
  }

  /// Gán toàn bộ thành viên trong nhóm cùng ăn món này
  void selectAllMembersForItem(String itemId, List<String> allMemberIds) {
    HapticFeedback.selectionClick();

    final currentMap = Map<String, List<String>>.from(state.itemAssignments);
    currentMap[itemId] = List<String>.from(allMemberIds);
    emit(state.copyWith(itemAssignments: currentMap));
  }

  /// Cập nhật thông tin món ăn (Tên, Số lượng, Đơn giá)
  void updateItem({
    required String itemId,
    String? name,
    double? quantity,
    int? unitPrice,
  }) {
    final updatedList = state.items.map((item) {
      if (item.id != itemId) return item;

      final updatedName = name ?? item.name;
      final updatedQty = quantity ?? item.quantity;
      final updatedPrice = unitPrice ?? item.unitPrice;
      final updatedTotal = (updatedQty * updatedPrice).round();

      return item.copyWith(
        name: updatedName,
        quantity: updatedQty,
        unitPrice: updatedPrice,
        totalPrice: updatedTotal,
      );
    }).toList();

    emit(state.copyWith(items: updatedList));
  }

  /// Thêm một món ăn trống vào danh sách
  void addBlankItem(List<String> allMemberIds) {
    HapticFeedback.lightImpact();

    final newItemId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = ParsedReceiptItemModel(
      id: newItemId,
      name: 'Món mới',
      quantity: 1,
      unitPrice: 20000,
      totalPrice: 20000,
      assignedTo: List<String>.from(allMemberIds),
    );

    final currentMap = Map<String, List<String>>.from(state.itemAssignments);
    currentMap[newItemId] = List<String>.from(allMemberIds);

    emit(state.copyWith(
      items: [...state.items, newItem],
      itemAssignments: currentMap,
    ));
  }

  /// Xóa một món ăn khỏi danh sách
  void removeItem(String itemId) {
    HapticFeedback.lightImpact();

    final updatedItems = state.items.where((i) => i.id != itemId).toList();
    final currentMap = Map<String, List<String>>.from(state.itemAssignments);
    currentMap.remove(itemId);

    emit(state.copyWith(
      items: updatedItems,
      itemAssignments: currentMap,
    ));
  }

  /// Cập nhật các loại phụ phí (Thuế VAT, Phí phục vụ, Giảm giá voucher)
  void updateExtraCharges({
    int? tax,
    int? serviceCharge,
    int? discount,
  }) {
    final updatedCharges = state.extraCharges.copyWith(
      tax: tax,
      serviceCharge: serviceCharge,
      discount: discount,
    );

    emit(state.copyWith(extraCharges: updatedCharges));
  }

  /// Lưu hóa đơn lên server Backend để phân bổ Pro-rata và tính nợ tối giản Greedy
  Future<void> submitExpense(
    String groupId, {
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    if (!state.isValidToSubmit) {
      const msg = 'Vui lòng kiểm tra lại: Mỗi món phải có ít nhất 1 người ăn và tổng tiền phải lớn hơn 0';
      onError?.call(msg);
      return;
    }

    emit(state.copyWith(status: BlocStatus.checking));

    // Đóng gói Payload chuẩn Mục 3.2 contract.md
    final payloadItems = state.items.map((item) {
      final assigned = state.itemAssignments[item.id] ?? item.assignedTo;
      return CreateExpensePayloadItem(
        name: item.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
        assignedTo: assigned,
      );
    }).toList();

    final payload = CreateExpensePayload(
      title: state.title,
      paidBy: state.paidByUserId,
      items: payloadItems,
      extraCharges: state.extraCharges,
      totalAmount: state.calculatedTotal,
    );

    final result = await _expenseRepositories.createExpense(
      groupId: groupId,
      payload: payload,
    );

    if (isClosed) return;

    if (result.isSuccess) {
      emit(state.copyWith(status: BlocStatus.success));
      onSuccess?.call();
    } else {
      final errorMsg = result.message ?? 'Không thể lưu hóa đơn';
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: errorMsg,
      ));
      onError?.call(errorMsg);
    }
  }
}
