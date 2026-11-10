import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/expense_model.dart';
import 'package:smartsplit_mobile/src/features/groups/domain/interfaces/i_group_repositories.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_model.dart';

part 'group_detail_state.dart';

/// Cubit quản lý chi tiết một nhóm cụ thể, danh sách hóa đơn, cấn trừ nợ và thêm thành viên.
class GroupDetailCubit extends Cubit<GroupDetailState> {
  final IGroupRepositories _groupRepositories;

  final TextEditingController memberEmailController = TextEditingController();

  GroupDetailCubit({
    required IGroupRepositories groupRepositories,
  })  : _groupRepositories = groupRepositories,
        super(const GroupDetailState());

  /// Tải thông tin chi tiết nhóm kèm danh sách hóa đơn
  Future<void> fetchGroupDetail(String groupId) async {
    emit(state.copyWith(status: BlocStatus.loading, errorMessage: null));

    final result = await _groupRepositories.getGroupDetail(groupId);

    if (isClosed) return;

    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(
        status: BlocStatus.hasData,
        group: result.data!.group,
        expenses: result.data!.expenses,
      ));
    } else {
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: result.message ?? 'Không thể tải chi tiết nhóm',
      ));
    }
  }

  /// Chuyển đổi tab hiển thị (0: Hóa đơn, 1: Cấn trừ nợ)
  void changeTab(int index) {
    if (state.selectedTabIndex != index) {
      emit(state.copyWith(selectedTabIndex: index));
    }
  }

  /// Thêm thành viên mới vào nhóm qua địa chỉ email
  Future<void> addMember(
    String groupId, {
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    final email = memberEmailController.text.trim();

    if (email.isEmpty) {
      const msg = 'Vui lòng nhập địa chỉ email của thành viên';
      onError?.call(msg);
      return;
    }

    emit(state.copyWith(isSubmittingAction: true));

    final result = await _groupRepositories.addMemberByEmail(
      groupId: groupId,
      email: email,
    );

    if (isClosed) return;

    emit(state.copyWith(isSubmittingAction: false));

    if (result.isSuccess) {
      memberEmailController.clear();
      // Tải lại chi tiết nhóm để đồng bộ danh sách thành viên mới nhất
      await fetchGroupDetail(groupId);
      if (isClosed) return;
      onSuccess?.call();
    } else {
      final errorMsg = result.message ?? 'Thêm thành viên không thành công';
      onError?.call(errorMsg);
    }
  }

  /// Xác nhận thanh toán khoản nợ (gạch nợ giữa 2 thành viên)
  Future<void> settleDebt({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required int amount,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    emit(state.copyWith(isSubmittingAction: true));

    final result = await _groupRepositories.settleDebt(
      groupId: groupId,
      fromUser: fromUserId,
      toUser: toUserId,
      amount: amount,
    );

    if (isClosed) return;

    emit(state.copyWith(isSubmittingAction: false));

    if (result.isSuccess) {
      // Tải lại chi tiết nhóm để cập nhật lại số dư ròng và danh sách nợ về 0
      await fetchGroupDetail(groupId);
      if (isClosed) return;
      onSuccess?.call();
    } else {
      final errorMsg = result.message ?? 'Xác nhận thanh toán thất bại';
      onError?.call(errorMsg);
    }
  }

  @override
  Future<void> close() {
    memberEmailController.dispose();
    return super.close();
  }
}
