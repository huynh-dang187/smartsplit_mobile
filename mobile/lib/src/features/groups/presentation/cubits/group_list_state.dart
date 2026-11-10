part of 'group_list_cubit.dart';

/// Trạng thái của màn hình danh sách nhóm.
final class GroupListState {
  final BlocStatus status;
  final List<GroupModel> groups;
  final String? errorMessage;

  const GroupListState({
    this.status = BlocStatus.init,
    this.groups = const [],
    this.errorMessage,
  });

  GroupListState copyWith({
    BlocStatus? status,
    List<GroupModel>? groups,
    String? errorMessage,
  }) {
    return GroupListState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      errorMessage: errorMessage,
    );
  }
}
