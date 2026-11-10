import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/expense_model.dart';
import 'group_model.dart';

/// Mô hình phản hồi dữ liệu chi tiết nhóm từ `GET /api/groups/:groupId`.
class GroupDetailResponseModel {
  final GroupModel group;
  final List<ExpenseModel> expenses;

  const GroupDetailResponseModel({
    required this.group,
    this.expenses = const [],
  });

  factory GroupDetailResponseModel.fromJson(Map<String, dynamic> json) {
    final rawGroup = json['group'];
    final groupModel = rawGroup is Map<String, dynamic>
        ? GroupModel.fromJson(rawGroup)
        : GroupModel(id: '', name: '', createdById: '');

    final rawExpenses = json['expenses'];
    final List<ExpenseModel> expensesList = [];
    if (rawExpenses is List) {
      for (final e in rawExpenses) {
        if (e is Map<String, dynamic>) {
          expensesList.add(ExpenseModel.fromJson(e));
        }
      }
    }

    return GroupDetailResponseModel(
      group: groupModel,
      expenses: expensesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group': group.toJson(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
  }

  GroupDetailResponseModel copyWith({
    GroupModel? group,
    List<ExpenseModel>? expenses,
  }) {
    return GroupDetailResponseModel(
      group: group ?? this.group,
      expenses: expenses ?? this.expenses,
    );
  }
}
