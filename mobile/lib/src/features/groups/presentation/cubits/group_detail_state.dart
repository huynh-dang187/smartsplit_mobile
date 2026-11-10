part of 'group_detail_cubit.dart';

/// Trạng thái của màn hình chi tiết nhóm, quản lý hóa đơn và cấn trừ nợ.
final class GroupDetailState {
  final BlocStatus status;
  final GroupModel? group;
  final List<ExpenseModel> expenses;
  final int selectedTabIndex; // 0: Tab Hóa đơn, 1: Tab Cấn trừ nợ
  final bool isSubmittingAction;
  final String? errorMessage;

  const GroupDetailState({
    this.status = BlocStatus.init,
    this.group,
    this.expenses = const [],
    this.selectedTabIndex = 0,
    this.isSubmittingAction = false,
    this.errorMessage,
  });

  /// Lấy số dư ròng của người dùng hiện tại trong nhóm này
  int getMyNetBalance(String currentUserId) {
    if (group == null) return 0;
    return group!.getUserNetBalance(currentUserId);
  }

  GroupDetailState copyWith({
    BlocStatus? status,
    GroupModel? group,
    List<ExpenseModel>? expenses,
    int? selectedTabIndex,
    bool? isSubmittingAction,
    String? errorMessage,
  }) {
    return GroupDetailState(
      status: status ?? this.status,
      group: group ?? this.group,
      expenses: expenses ?? this.expenses,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      errorMessage: errorMessage,
    );
  }
}
