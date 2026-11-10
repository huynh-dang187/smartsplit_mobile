import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/features/auth/domain/interfaces/i_auth_repositories.dart';
import 'package:smartsplit_mobile/src/features/expenses/domain/interfaces/i_expense_repositories.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/create_expense_payload.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/parsed_receipt_model.dart';
import 'package:smartsplit_mobile/src/features/groups/domain/interfaces/i_group_repositories.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_detail_response_model.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_model.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await initDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('GroupModel JSON Serialization Tests', () {
    test('Parse GroupModel khi userId chưa populate (dạng String ID)', () {
      final rawJson = {
        '_id': 'group_123',
        'name': 'Hội Ăn Trưa',
        'description': 'Chia tiền ăn trưa',
        'createdBy': 'user_creator_id',
        'members': [
          {
            'userId': 'user_creator_id',
            'netBalance': 0,
          },
          {
            'userId': 'user_member_2',
            'netBalance': -50000,
          },
        ],
        'simplifiedDebts': [
          {
            'fromUser': 'user_member_2',
            'toUser': 'user_creator_id',
            'amount': 50000,
          }
        ],
        'createdAt': '2026-11-10T08:00:00.000Z',
      };

      final group = GroupModel.fromJson(rawJson);

      expect(group.id, 'group_123');
      expect(group.name, 'Hội Ăn Trưa');
      expect(group.totalMembers, 2);
      expect(group.members[0].memberId, 'user_creator_id');
      expect(group.members[0].isPopulated, isFalse);
      expect(group.members[1].netBalance, -50000);
      expect(group.simplifiedDebts.length, 1);
      expect(group.simplifiedDebts[0].fromUserId, 'user_member_2');
      expect(group.simplifiedDebts[0].toUserId, 'user_creator_id');
      expect(group.simplifiedDebts[0].amount, 50000);

      // Kiểm tra toJson round-trip
      final exportedJson = group.toJson();
      expect(exportedJson['_id'], 'group_123');
      expect(exportedJson['members'].length, 2);
    });

    test('Parse GroupModel khi userId đã populate thông tin UserModel & bankInfo', () {
      final rawJson = {
        '_id': 'group_detail_456',
        'name': 'Du Lịch Đà Lạt',
        'createdBy': {
          '_id': 'user_admin',
          'name': 'Trần Thị B',
          'email': 'b@gmail.com',
        },
        'members': [
          {
            'userId': {
              '_id': 'user_admin',
              'name': 'Trần Thị B',
              'email': 'b@gmail.com',
              'avatarUrl': 'https://example.com/b.png',
              'bankInfo': {
                'bankBin': '970436',
                'bankShortName': 'VCB',
                'accountNo': '1234567890',
                'accountName': 'TRAN THI B',
              },
            },
            'netBalance': 150000,
          },
          {
            'userId': {
              '_id': 'user_debtor',
              'name': 'Lê Văn C',
              'email': 'c@gmail.com',
            },
            'netBalance': -150000,
          },
        ],
        'simplifiedDebts': [
          {
            'fromUser': {
              '_id': 'user_debtor',
              'name': 'Lê Văn C',
              'email': 'c@gmail.com',
            },
            'toUser': {
              '_id': 'user_admin',
              'name': 'Trần Thị B',
              'email': 'b@gmail.com',
              'bankInfo': {
                'bankBin': '970436',
                'bankShortName': 'VCB',
                'accountNo': '1234567890',
                'accountName': 'TRAN THI B',
              },
            },
            'amount': 150000,
          }
        ],
      };

      final group = GroupModel.fromJson(rawJson);

      expect(group.id, 'group_detail_456');
      expect(group.members[0].isPopulated, isTrue);
      expect(group.members[0].memberName, 'Trần Thị B');
      expect(group.members[0].memberBankInfo?.bankBin, '970436');
      expect(group.members[0].memberBankInfo?.accountNo, '1234567890');
      expect(group.members[0].memberBankInfo?.isComplete, isTrue);

      // Kiểm tra khoản nợ tối giản có đầy đủ thông tin VietQR của chủ nợ
      final debt = group.simplifiedDebts[0];
      expect(debt.fromUserName, 'Lê Văn C');
      expect(debt.toUserName, 'Trần Thị B');
      expect(debt.toUserBankInfo?.bankShortName, 'VCB');
      expect(debt.amount, 150000);
    });
  });

  group('ParsedReceiptModel & isDiscrepancy Tests', () {
    test('Parse ParsedReceiptModel chính xác với cờ cảnh báo isDiscrepancy: true', () {
      final receiptJson = {
        'items': [
          {
            'id': 'item_1',
            'name': 'Lẩu Thái Tomyum',
            'quantity': 1,
            'unitPrice': 250000,
            'totalPrice': 250000,
            'assignedTo': ['user_1', 'user_2'],
          },
          {
            'id': 'item_2',
            'name': 'Khăn lạnh',
            'quantity': 4,
            'unitPrice': 5000,
            'totalPrice': 20000,
            'assignedTo': ['user_1'],
          },
        ],
        'extraCharges': {
          'tax': 25000,
          'serviceCharge': 10000,
          'discount': 5000,
        },
        'subtotalAmount': 270000,
        'totalAmount': 350000, // Cố tình lệch so với 270k + 30k = 300k
        'calculatedTotal': 300000,
        'isDiscrepancy': true,
      };

      final parsed = ParsedReceiptModel.fromJson(receiptJson);

      expect(parsed.items.length, 2);
      expect(parsed.items[0].name, 'Lẩu Thái Tomyum');
      expect(parsed.items[0].assignedTo, ['user_1', 'user_2']);
      expect(parsed.extraCharges.tax, 25000);
      expect(parsed.extraCharges.serviceCharge, 10000);
      expect(parsed.extraCharges.discount, 5000);
      expect(parsed.extraCharges.netExtra, 30000);
      expect(parsed.subtotalAmount, 270000);
      expect(parsed.totalAmount, 350000);
      expect(parsed.calculatedTotal, 300000);
      expect(parsed.isDiscrepancy, isTrue);

      // copyWith toggle cờ cảnh báo
      final resolved = parsed.copyWith(isDiscrepancy: false);
      expect(resolved.isDiscrepancy, isFalse);
    });
  });

  group('CreateExpensePayload Tests', () {
    test('CreateExpensePayload toJson khớp 100% Mục 3.2 contract.md', () {
      const payload = CreateExpensePayload(
        title: 'Ăn tối King BBQ',
        paidBy: 'user_an',
        items: [
          CreateExpensePayloadItem(
            name: 'Buffet Nướng',
            quantity: 3,
            unitPrice: 299000,
            totalPrice: 897000,
            assignedTo: ['user_an', 'user_binh', 'user_cuong'],
          ),
          CreateExpensePayloadItem(
            name: 'Nước ngọt',
            quantity: 3,
            unitPrice: 20000,
            totalPrice: 60000,
            assignedTo: ['user_an', 'user_binh'],
          ),
        ],
        extraCharges: ExtraChargesModel(
          tax: 95700,
          serviceCharge: 0,
          discount: 50000,
        ),
        totalAmount: 1002700,
      );

      final json = payload.toJson();

      expect(json['title'], 'Ăn tối King BBQ');
      expect(json['paidBy'], 'user_an');
      expect(json['totalAmount'], 1002700);

      final items = json['items'] as List;
      expect(items.length, 2);
      expect(items[0]['name'], 'Buffet Nướng');
      expect(items[0]['quantity'], 3);
      expect(items[0]['assignedTo'], ['user_an', 'user_binh', 'user_cuong']);

      final extra = json['extraCharges'] as Map;
      expect(extra['tax'], 95700);
      expect(extra['discount'], 50000);
    });
  });

  group('GroupDetailResponseModel & ExpenseModel Tests', () {
    test('Parse GroupDetailResponseModel gồm Group và Expenses', () {
      final responseJson = {
        'group': {
          '_id': 'group_789',
          'name': 'Nhóm Đá Banh',
          'createdBy': 'user_cap',
          'members': [
            {'userId': 'user_cap', 'netBalance': 0}
          ],
        },
        'expenses': [
          {
            '_id': 'exp_1',
            'groupId': 'group_789',
            'title': 'Tiền sân cỏ nhân tạo',
            'type': 'BILL',
            'paidBy': {
              '_id': 'user_cap',
              'name': 'Đội Trưởng',
              'email': 'cap@gmail.com',
            },
            'items': [
              {
                'name': 'Sân 7 người 90 phút',
                'quantity': 1,
                'unitPrice': 600000,
                'totalPrice': 600000,
                'assignedTo': ['user_cap'],
              }
            ],
            'extraCharges': {'tax': 0, 'serviceCharge': 0, 'discount': 0},
            'memberShares': [
              {
                'userId': 'user_cap',
                'baseAmount': 600000,
                'extraAmount': 0,
                'finalAmount': 600000,
              }
            ],
            'subtotalAmount': 600000,
            'totalAmount': 600000,
            'createdAt': '2026-11-10T10:00:00.000Z',
          }
        ],
      };

      final detail = GroupDetailResponseModel.fromJson(responseJson);

      expect(detail.group.id, 'group_789');
      expect(detail.expenses.length, 1);
      expect(detail.expenses[0].isBill, isTrue);
      expect(detail.expenses[0].paidByName, 'Đội Trưởng');
      expect(detail.expenses[0].totalAmount, 600000);
    });
  });

  group('Service Locator Dependency Injection Tests', () {
    test('Đăng ký và trích xuất thành công cả 3 Feature Repositories từ GetIt', () {
      final authRepo = getIt<IAuthRepositories>();
      final groupRepo = getIt<IGroupRepositories>();
      final expenseRepo = getIt<IExpenseRepositories>();

      expect(authRepo, isNotNull);
      expect(groupRepo, isNotNull);
      expect(expenseRepo, isNotNull);
    });
  });
}
