import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/bank_info_model.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/expense_model.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/parsed_receipt_model.dart';
import 'package:smartsplit_mobile/src/features/groups/domain/interfaces/i_group_repositories.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_detail_response_model.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_member_model.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_model.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/simplified_debt_model.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_detail_cubit.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_list_cubit.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/widgets/group_balance_card.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/widgets/vietqr_bottom_sheet.dart';

/// Fake repository phục vụ kiểm thử Feature Groups
class FakeGroupRepository implements IGroupRepositories {
  bool shouldSucceed = true;
  String? mockErrorMessage;

  final GroupModel mockGroup = const GroupModel(
    id: 'group_1',
    name: 'Ăn trưa công ty',
    description: 'Nhóm ăn trưa hàng ngày',
    createdById: 'user_1',
    members: [
      GroupMemberModel(rawUserId: 'user_1', netBalance: 150000),
      GroupMemberModel(rawUserId: 'user_2', netBalance: -150000),
    ],
    simplifiedDebts: [
      SimplifiedDebtModel(
        rawFromUser: 'user_2',
        fromUserModel: UserModel(id: 'user_2', name: 'Trần Thị B', email: 'b@gmail.com'),
        rawToUser: 'user_1',
        toUserModel: UserModel(
          id: 'user_1',
          name: 'Nguyễn Văn A',
          email: 'a@gmail.com',
          bankInfo: BankInfoModel(
            bankBin: '970422',
            bankShortName: 'MB',
            accountNo: '1029384756',
            accountName: 'NGUYEN VAN A',
          ),
        ),
        amount: 150000,
      ),
    ],
  );

  @override
  Future<BaseResult<GroupModel>> createGroup({
    required String name,
    String? description,
  }) async {
    if (shouldSucceed) {
      return BaseResult.ok(
        GroupModel(
          id: 'group_new',
          name: name,
          description: description,
          createdById: 'user_1',
          members: const [GroupMemberModel(rawUserId: 'user_1', netBalance: 0)],
        ),
        message: 'Tạo nhóm thành công',
      );
    }
    return BaseResult.fail(mockErrorMessage ?? 'Tạo nhóm thất bại');
  }

  @override
  Future<BaseResult<List<GroupModel>>> getMyGroups() async {
    if (shouldSucceed) {
      return BaseResult.ok([mockGroup], message: 'Thành công');
    }
    return BaseResult.fail(mockErrorMessage ?? 'Không thể tải nhóm');
  }

  @override
  Future<BaseResult<GroupDetailResponseModel>> getGroupDetail(String groupId) async {
    if (shouldSucceed) {
      return BaseResult.ok(
        GroupDetailResponseModel(
          group: mockGroup,
          expenses: const [
            ExpenseModel(
              id: 'exp_1',
              groupId: 'group_1',
              title: 'Cơm trưa văn phòng',
              type: 'BILL',
              paidById: 'user_1',
              paidByUser: UserModel(id: 'user_1', name: 'Nguyễn Văn A', email: 'a@gmail.com'),
              items: [],
              extraCharges: ExtraChargesModel(tax: 0, serviceCharge: 0, discount: 0),
              memberShares: [],
              subtotalAmount: 150000,
              totalAmount: 150000,
            ),
          ],
        ),
        message: 'Thành công',
      );
    }
    return BaseResult.fail(mockErrorMessage ?? 'Nhóm không tồn tại');
  }

  @override
  Future<BaseResult<GroupModel>> addMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    if (shouldSucceed) {
      return BaseResult.ok(mockGroup, message: 'Thêm thành viên thành công');
    }
    return BaseResult.fail(mockErrorMessage ?? 'Email chưa đăng ký');
  }

  @override
  Future<BaseResult<GroupModel>> settleDebt({
    required String groupId,
    required String fromUser,
    required String toUser,
    required int amount,
  }) async {
    if (shouldSucceed) {
      return BaseResult.ok(mockGroup, message: 'Thanh toán thành công');
    }
    return BaseResult.fail(mockErrorMessage ?? 'Gạch nợ thất bại');
  }
}

void main() {
  group('GroupListCubit Unit Tests', () {
    late FakeGroupRepository fakeRepo;
    late GroupListCubit cubit;

    setUp(() {
      fakeRepo = FakeGroupRepository();
      cubit = GroupListCubit(groupRepositories: fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('Khởi tạo ban đầu với trạng thái init và danh sách rỗng', () {
      expect(cubit.state.status, BlocStatus.init);
      expect(cubit.state.groups, isEmpty);
      expect(cubit.nameController.text, isEmpty);
      expect(cubit.descriptionController.text, isEmpty);
    });

    test('fetchMyGroups thành công nạp danh sách nhóm', () async {
      await cubit.fetchMyGroups();

      expect(cubit.state.status, BlocStatus.hasData);
      expect(cubit.state.groups.length, 1);
      expect(cubit.state.groups.first.name, 'Ăn trưa công ty');
    });

    test('fetchMyGroups thất bại chuyển sang trạng thái error', () async {
      fakeRepo.shouldSucceed = false;
      fakeRepo.mockErrorMessage = 'Lỗi kết nối máy chủ';

      await cubit.fetchMyGroups();

      expect(cubit.state.status, BlocStatus.error);
      expect(cubit.state.errorMessage, 'Lỗi kết nối máy chủ');
    });

    test('createGroup validate bắt buộc tên nhóm', () async {
      bool errorCalled = false;
      String? receivedError;

      await cubit.createGroup(
        onError: (err) {
          errorCalled = true;
          receivedError = err;
        },
      );

      expect(errorCalled, isTrue);
      expect(receivedError, 'Vui lòng nhập tên nhóm');
      expect(cubit.state.status, BlocStatus.validateError);
    });

    test('createGroup thành công thêm nhóm vào đầu danh sách', () async {
      cubit.nameController.text = 'Nhóm Đi Chơi Mới';
      cubit.descriptionController.text = 'Mô tả';

      bool successCalled = false;
      await cubit.createGroup(
        onSuccess: () => successCalled = true,
      );

      expect(successCalled, isTrue);
      expect(cubit.state.status, BlocStatus.hasData);
      expect(cubit.state.groups.length, 1);
      expect(cubit.state.groups.first.name, 'Nhóm Đi Chơi Mới');
      expect(cubit.nameController.text, isEmpty);
      expect(cubit.descriptionController.text, isEmpty);
    });
  });

  group('GroupDetailCubit Unit Tests', () {
    late FakeGroupRepository fakeRepo;
    late GroupDetailCubit cubit;

    setUp(() {
      fakeRepo = FakeGroupRepository();
      cubit = GroupDetailCubit(groupRepositories: fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('Khởi tạo ban đầu với trạng thái init và selectedTabIndex = 0', () {
      expect(cubit.state.status, BlocStatus.init);
      expect(cubit.state.group, isNull);
      expect(cubit.state.expenses, isEmpty);
      expect(cubit.state.selectedTabIndex, 0);
    });

    test('fetchGroupDetail thành công nạp group và expenses', () async {
      await cubit.fetchGroupDetail('group_1');

      expect(cubit.state.status, BlocStatus.hasData);
      expect(cubit.state.group, isNotNull);
      expect(cubit.state.group!.name, 'Ăn trưa công ty');
      expect(cubit.state.expenses.length, 1);
      expect(cubit.state.expenses.first.title, 'Cơm trưa văn phòng');
    });

    test('changeTab chuyển đổi tab chính xác', () {
      cubit.changeTab(1);
      expect(cubit.state.selectedTabIndex, 1);

      cubit.changeTab(0);
      expect(cubit.state.selectedTabIndex, 0);
    });

    test('getMyNetBalance trả về số dư ròng chuẩn xác của user', () async {
      await cubit.fetchGroupDetail('group_1');

      // User 1 là chủ nợ (+150.000đ)
      expect(cubit.state.getMyNetBalance('user_1'), 150000);
      // User 2 là con nợ (-150.000đ)
      expect(cubit.state.getMyNetBalance('user_2'), -150000);
      // User 3 không trong nhóm (0đ)
      expect(cubit.state.getMyNetBalance('user_3'), 0);
    });

    test('addMember kiểm tra email rỗng', () async {
      bool errorCalled = false;
      await cubit.addMember(
        'group_1',
        onError: (_) => errorCalled = true,
      );

      expect(errorCalled, isTrue);
    });

    test('addMember thành công gọi onSuccess', () async {
      cubit.memberEmailController.text = 'newmember@gmail.com';

      bool successCalled = false;
      await cubit.addMember(
        'group_1',
        onSuccess: () => successCalled = true,
      );

      expect(successCalled, isTrue);
      expect(cubit.memberEmailController.text, isEmpty);
    });

    test('settleDebt thành công gọi onSuccess', () async {
      bool successCalled = false;
      await cubit.settleDebt(
        groupId: 'group_1',
        fromUserId: 'user_2',
        toUserId: 'user_1',
        amount: 150000,
        onSuccess: () => successCalled = true,
      );

      expect(successCalled, isTrue);
    });
  });

  group('Group Feature UI Render Tests', () {
    testWidgets('GroupBalanceCard hiển thị đúng số dư dương (Bạn được nhận lại)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupBalanceCard(
              groupName: 'Ăn trưa công ty',
              netBalance: 150000,
              onTapSettle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ăn trưa công ty'), findsOneWidget);
      expect(find.text('Bạn được nhận lại'), findsOneWidget);
      expect(find.textContaining('150.000'), findsOneWidget);
      // Không có nút VietQR vì số dư dương
      expect(find.text('Thanh toán ngay qua VietQR'), findsNothing);
    });

    testWidgets('GroupBalanceCard hiển thị số dư âm (Bạn cần trả) kèm nút VietQR', (tester) async {
      bool settlePressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupBalanceCard(
              groupName: 'Ăn trưa công ty',
              netBalance: -75000,
              onTapSettle: () => settlePressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Bạn cần trả'), findsOneWidget);
      expect(find.textContaining('75.000'), findsOneWidget);
      expect(find.text('Thanh toán ngay qua VietQR'), findsOneWidget);

      await tester.tap(find.text('Thanh toán ngay qua VietQR'));
      expect(settlePressed, isTrue);
    });

    testWidgets('GroupBalanceCard hiển thị trạng thái sòng phẳng (netBalance == 0)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupBalanceCard(
              groupName: 'Nhóm đã tất toán',
              netBalance: 0,
              onTapSettle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Đã sòng phẳng'), findsOneWidget);
      expect(find.textContaining('0'), findsWidgets);
    });

    testWidgets('VietQrBottomSheet render đầy đủ thông tin thanh toán và nút xác nhận', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final debt = const SimplifiedDebtModel(
        rawFromUser: 'user_2',
        fromUserModel: UserModel(id: 'user_2', name: 'Trần Thị B', email: 'b@gmail.com'),
        rawToUser: 'user_1',
        toUserModel: UserModel(
          id: 'user_1',
          name: 'Nguyễn Văn A',
          email: 'a@gmail.com',
          bankInfo: BankInfoModel(
            bankBin: '970422',
            bankShortName: 'MB',
            accountNo: '1029384756',
            accountName: 'NGUYEN VAN A',
          ),
        ),
        amount: 150000,
      );

      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VietQrBottomSheet(
              debt: debt,
              groupName: 'Ăn trưa công ty',
              onConfirmSettled: () => confirmed = true,
            ),
          ),
        ),
      );

      // Verify title & Bank info
      expect(find.text('Thanh toán chuyển khoản VietQR'), findsOneWidget);
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('MB'), findsOneWidget);
      expect(find.text('1029384756'), findsOneWidget);
      expect(find.textContaining('150.000'), findsOneWidget);
      expect(find.text('Tôi đã chuyển khoản xong'), findsOneWidget);

      // Ensure button is visible before tap
      await tester.ensureVisible(find.text('Tôi đã chuyển khoản xong'));
      await tester.pump();

      // Tap confirm button
      await tester.tap(find.text('Tôi đã chuyển khoản xong'));
      await tester.pump();
      expect(confirmed, isTrue);
    });
  });
}
