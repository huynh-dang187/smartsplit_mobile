import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/features/groups/domain/interfaces/i_group_repositories.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_model.dart';

part 'group_list_state.dart';

/// Cubit quản lý danh sách các nhóm mà người dùng tham gia và tác vụ tạo nhóm mới.
class GroupListCubit extends Cubit<GroupListState> {
  final IGroupRepositories _groupRepositories;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  GroupListCubit({
    required IGroupRepositories groupRepositories,
  })  : _groupRepositories = groupRepositories,
        super(const GroupListState());

  /// Tải danh sách nhóm của người dùng hiện tại
  Future<void> fetchMyGroups() async {
    emit(state.copyWith(status: BlocStatus.loading, errorMessage: null));

    final result = await _groupRepositories.getMyGroups();

    if (isClosed) return;

    if (result.isSuccess) {
      emit(state.copyWith(
        status: BlocStatus.hasData,
        groups: result.data ?? [],
      ));
    } else {
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: result.message ?? 'Không thể tải danh sách nhóm',
      ));
    }
  }

  /// Tạo nhóm chia tiền mới
  Future<void> createGroup({
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      const msg = 'Vui lòng nhập tên nhóm';
      emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
      onError?.call(msg);
      return;
    }

    emit(state.copyWith(status: BlocStatus.loading, errorMessage: null));

    final result = await _groupRepositories.createGroup(
      name: name,
      description: description.isNotEmpty ? description : null,
    );

    if (isClosed) return;

    if (result.isSuccess && result.data != null) {
      final newGroup = result.data!;
      final updatedList = [newGroup, ...state.groups];
      nameController.clear();
      descriptionController.clear();
      emit(state.copyWith(
        status: BlocStatus.hasData,
        groups: updatedList,
      ));
      onSuccess?.call();
    } else {
      final errorMsg = result.message ?? 'Tạo nhóm không thành công';
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: errorMsg,
      ));
      onError?.call(errorMsg);
    }
  }

  @override
  Future<void> close() {
    nameController.dispose();
    descriptionController.dispose();
    return super.close();
  }
}
