import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/features/expenses/domain/interfaces/i_expense_repositories.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/create_expense_payload.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/expense_model.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/parsed_receipt_model.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/cubits/split_workspace_cubit.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/widgets/discrepancy_warning_banner.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/widgets/member_share_bottom_bar.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/widgets/receipt_item_card.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_member_model.dart';

/// Fake repository phục vụ kiểm thử Feature Expenses
class FakeExpenseRepository implements IExpenseRepositories {
  bool shouldSucceed = true;
  String? mockErrorMessage;

  final ParsedReceiptModel mockReceipt = const ParsedReceiptModel(
    items: [
      ParsedReceiptItemModel(
        id: 'item_1',
        name: 'Phở bò tái',
        quantity: 2,
        unitPrice: 50000,
        totalPrice: 100000,
      ),
      ParsedReceiptItemModel(
        id: 'item_2',
        name: 'Trà đá',
        quantity: 2,
        unitPrice: 5000,
        totalPrice: 10000,
      ),
    ],
    extraCharges: ExtraChargesModel(tax: 11000, serviceCharge: 0, discount: 0),
    subtotalAmount: 110000,
    totalAmount: 121000,
    calculatedTotal: 121000,
    isDiscrepancy: false,
  );

  @override
  Future<BaseResult<ParsedReceiptModel>> scanReceipt(String imagePath) async {
    if (shouldSucceed) {
      return BaseResult.ok(mockReceipt, message: 'Bóc tách thành công');
    }
    return BaseResult.fail(mockErrorMessage ?? 'AI không thể đọc được hóa đơn');
  }

  @override
  Future<BaseResult<ExpenseModel>> createExpense({
    required String groupId,
    required CreateExpensePayload payload,
  }) async {
    if (shouldSucceed) {
      return BaseResult.ok(
        ExpenseModel(
          id: 'exp_new',
          groupId: groupId,
          title: payload.title,
          type: 'BILL',
          paidById: payload.paidBy,
          items: const [],
          extraCharges: payload.extraCharges,
          memberShares: const [],
          subtotalAmount: payload.totalAmount,
          totalAmount: payload.totalAmount,
        ),
        message: 'Tạo hóa đơn thành công',
      );
    }
    return BaseResult.fail(mockErrorMessage ?? 'Không thể lưu hóa đơn');
  }
}

void main() {
  group('SplitWorkspaceCubit Unit & Pro-rata Math Tests', () {
    late FakeExpenseRepository fakeRepo;
    late SplitWorkspaceCubit cubit;
    const memberIds = ['user_A', 'user_B'];

    setUp(() {
      fakeRepo = FakeExpenseRepository();
      cubit = SplitWorkspaceCubit(expenseRepositories: fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('initManualBill khởi tạo đúng 1 món mẫu và người trả', () {
      cubit.initManualBill(memberIds, 'user_A');

      expect(cubit.state.status, BlocStatus.hasData);
      expect(cubit.state.items.length, 1);
      expect(cubit.state.paidByUserId, 'user_A');
      expect(cubit.state.items.first.name, 'Món ăn 1');
      expect(cubit.state.itemAssignments.values.first, containsAll(memberIds));
      expect(cubit.state.subtotalAmount, 50000);
      expect(cubit.state.calculatedTotal, 50000);
      expect(cubit.state.isValidToSubmit, isTrue);
    });

    test('scanReceiptImage nạp dữ liệu AI và tự động gán cả nhóm vào mọi món', () async {
      await cubit.scanReceiptImage(
        'mock/path/receipt.jpg',
        memberIds,
        currentUserId: 'user_A',
      );

      expect(cubit.state.status, BlocStatus.hasData);
      expect(cubit.state.items.length, 2);
      expect(cubit.state.subtotalAmount, 110000);
      expect(cubit.state.extraCharges.tax, 11000);
      expect(cubit.state.calculatedTotal, 121000);
      expect(cubit.state.receiptTotalAmount, 121000);
      expect(cubit.state.isDiscrepancy, isFalse);

      // Cả 2 món đều được gán cho cả 2 người
      expect(cubit.state.itemAssignments['item_1'], containsAll(memberIds));
      expect(cubit.state.itemAssignments['item_2'], containsAll(memberIds));
    });

    test('Cảnh báo isDiscrepancy khi calculatedTotal khác receiptTotalAmount', () {
      cubit.initManualBill(memberIds, 'user_A');
      // Ban đầu receiptTotalAmount = 50000, calculatedTotal = 50000 -> false
      expect(cubit.state.isDiscrepancy, isFalse);

      // Thêm thuế 5000 -> calculatedTotal = 55000 != 50000 -> true
      cubit.updateExtraCharges(tax: 5000);
      expect(cubit.state.isDiscrepancy, isTrue);
    });

    test('Thuật toán Pro-rata tính toán realtime khớp 100% mục 4.1 contract.md', () {
      // Thiết lập kịch bản:
      // Item 1: 60.000đ (cả user_A và user_B cùng ăn -> mỗi người 30.000đ)
      // Item 2: 40.000đ (chỉ user_A ăn -> 40.000đ)
      // Tổng món gốc S = 100.000đ.
      // Tiền món gốc: B_A = 70.000đ (70%), B_B = 30.000đ (30%).
      // Phụ phí ròng: Thuế VAT 10.000đ.
      // Tổng thực trả T = 110.000đ.
      // Phụ phí phân bổ: E_A = 10.000 * 70% = 7.000đ -> F_A = 77.000đ.
      // E_B = 10.000 * 30% = 3.000đ -> F_B = 33.000đ.
      // Tổng phần chia = 77.000 + 33.000 = 110.000đ.

      cubit.initManualBill(memberIds, 'user_A');

      // Cập nhật món 1
      final itemId1 = cubit.state.items.first.id;
      cubit.updateItem(itemId: itemId1, name: 'Lẩu bò', quantity: 1, unitPrice: 60000);
      cubit.selectAllMembersForItem(itemId1, memberIds);

      // Thêm món 2
      cubit.addBlankItem(memberIds);
      final itemId2 = cubit.state.items.last.id;
      cubit.updateItem(itemId: itemId2, name: 'Bia riêng', quantity: 1, unitPrice: 40000);

      // Chỉ gán user_A cho món 2
      cubit.toggleMemberForItem(itemId2, 'user_B'); // Bỏ user_B

      // Thêm thuế VAT 10.000đ
      cubit.updateExtraCharges(tax: 10000);

      expect(cubit.state.subtotalAmount, 100000);
      expect(cubit.state.calculatedTotal, 110000);

      final shares = cubit.state.realtimeMemberShares;
      expect(shares['user_A'], 77000);
      expect(shares['user_B'], 33000);
      expect(shares['user_A']! + shares['user_B']!, 110000);
    });

    test('Bù sai số làm tròn Delta vào người thanh toán (paidByUserId)', () {
      // 1 món 100.000đ chia cho 3 người (A, B, C):
      // 100.000 / 3 = 33333.33 -> round = 33333đ mỗi người.
      // Tổng = 99999đ. Thiếu 1đ.
      // Delta = 1đ được cộng dồn vào paidByUserId (user_A -> 33334đ).

      const threeMembers = ['user_A', 'user_B', 'user_C'];
      cubit.initManualBill(threeMembers, 'user_A');
      final itemId = cubit.state.items.first.id;
      cubit.updateItem(itemId: itemId, unitPrice: 100000, quantity: 1);
      cubit.selectAllMembersForItem(itemId, threeMembers);

      final shares = cubit.state.realtimeMemberShares;
      expect(shares['user_A'], 33334); // được bù sai số +1đ
      expect(shares['user_B'], 33333);
      expect(shares['user_C'], 33333);
      expect(shares['user_A']! + shares['user_B']! + shares['user_C']!, 100000);
    });

    test('submitExpense chặn khi có món chưa ai ăn', () async {
      cubit.initManualBill(memberIds, 'user_A');
      final itemId = cubit.state.items.first.id;

      // Bỏ chọn cả 2 người khỏi món 1
      cubit.toggleMemberForItem(itemId, 'user_A');
      cubit.toggleMemberForItem(itemId, 'user_B');

      expect(cubit.state.isValidToSubmit, isFalse);

      bool errorCalled = false;
      await cubit.submitExpense(
        'group_1',
        onError: (_) => errorCalled = true,
      );

      expect(errorCalled, isTrue);
    });

    test('submitExpense thành công gọi onSuccess', () async {
      cubit.initManualBill(memberIds, 'user_A');

      bool successCalled = false;
      await cubit.submitExpense(
        'group_1',
        onSuccess: () => successCalled = true,
      );

      expect(successCalled, isTrue);
      expect(cubit.state.status, BlocStatus.success);
    });
  });

  group('Expense Feature UI Widgets Render Tests', () {
    const mockMembers = [
      GroupMemberModel(rawUserId: 'user_A', netBalance: 0),
      GroupMemberModel(rawUserId: 'user_B', netBalance: 0),
    ];

    testWidgets('DiscrepancyWarningBanner render đúng số tiền và thông điệp cảnh báo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiscrepancyWarningBanner(
              calculatedTotal: 125000,
              receiptTotalAmount: 120000,
            ),
          ),
        ),
      );

      expect(find.text('Cảnh báo chênh lệch hóa đơn AI'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('125.000') && w.text.toPlainText().contains('120.000'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('ReceiptItemCard render tên món, thành tiền và danh sách chips thành viên', (tester) async {
      const item = ParsedReceiptItemModel(
        id: 'item_1',
        name: 'Cơm tấm sườn bì chả',
        quantity: 2,
        unitPrice: 45000,
        totalPrice: 90000,
      );

      bool memberToggled = false;
      bool allSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptItemCard(
              item: item,
              assignedMemberIds: const ['user_A'],
              groupMembers: mockMembers,
              onToggleMember: (uid) => memberToggled = true,
              onSelectAllMembers: () => allSelected = true,
              onEditItem: (name, qty, price) {},
              onDeleteItem: () {},
            ),
          ),
        ),
      );

      expect(find.text('Cơm tấm sườn bì chả'), findsOneWidget);
      expect(find.textContaining('90.000'), findsOneWidget);
      expect(find.text('Cả nhóm (2)'), findsOneWidget);

      await tester.tap(find.text('Cả nhóm (2)'));
      expect(allSelected, isTrue);

      await tester.tap(find.text('Thành viên (user_A)'));
      expect(memberToggled, isTrue);
    });

    testWidgets('MemberShareBottomBar hiển thị số tiền realtime và nút Lưu hóa đơn', (tester) async {
      bool submitTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberShareBottomBar(
              calculatedTotal: 150000,
              realtimeMemberShares: const {
                'user_A': 75000,
                'user_B': 75000,
              },
              groupMembers: mockMembers,
              isLoading: false,
              isValidToSubmit: true,
              onSubmit: () => submitTapped = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('150.000'), findsWidgets);
      expect(find.textContaining('75.000'), findsWidgets);

      await tester.tap(find.textContaining('Lưu & Chia Hóa Đơn'));
      expect(submitTapped, isTrue);
    });
  });
}
