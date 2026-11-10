import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/cubit/app/app_cubit.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_error_view.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_loading.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_list_cubit.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/pages/group_detail_screen.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/widgets/create_group_bottom_sheet.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/widgets/group_balance_card.dart';
import 'package:smartsplit_mobile/src/shared/router/app_router.dart';

/// Màn hình danh sách nhóm chia tiền của người dùng.
class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GroupListCubit>()..fetchMyGroups(),
      child: const _GroupListView(),
    );
  }
}

class _GroupListView extends StatelessWidget {
  const _GroupListView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupListCubit>();
    final currentUser = context.watch<AppCubit>().state.currentUser;
    final currentUserId = currentUser?.id ?? '';
    final userName = currentUser?.name ?? 'Bạn';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, $userName 👋',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'SmartSplit • Quản lý chi tiêu nhóm',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ & Tài khoản VietQR',
            icon: const Icon(Icons.account_circle_outlined, size: 26, color: AppColors.textPrimary),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.profileBank);
            },
          ),
          AppSpacing.gapHorizontalSm,
        ],
      ),
      body: BlocBuilder<GroupListCubit, GroupListState>(
        builder: (context, state) {
          if (state.status.isLoading) {
            return const _LoadingListShimmer();
          }

          if (state.status.isError) {
            return CommonErrorView(
              message: state.errorMessage ?? 'Không thể tải danh sách nhóm',
              onRetry: () => cubit.fetchMyGroups(),
            );
          }

          if (state.groups.isEmpty) {
            return _EmptyGroupView(
              onCreateGroup: () => CreateGroupBottomSheet.show(context, cubit: cubit),
            );
          }

          return RefreshIndicator(
            onRefresh: () => cubit.fetchMyGroups(),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: 80, // Chừa khoảng trống cho FAB
              ),
              itemCount: state.groups.length,
              itemBuilder: (context, index) {
                final group = state.groups[index];
                final netBalance = group.getUserNetBalance(currentUserId);

                return GroupBalanceCard(
                  groupName: group.name,
                  netBalance: netBalance,
                  subtitle: '${group.members.length} thành viên',
                  onTapCard: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: group.id),
                      ),
                    ).then((_) => cubit.fetchMyGroups());
                  },
                  onTapSettle: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(
                          groupId: group.id,
                          initialTabIndex: 1, // Mở thẳng Tab Cấn trừ nợ
                        ),
                      ),
                    ).then((_) => cubit.fetchMyGroups());
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateGroupBottomSheet.show(context, cubit: cubit),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Tạo nhóm mới',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

/// Shimmer Skeleton hiển thị khi đang tải danh sách nhóm
class _LoadingListShimmer extends StatelessWidget {
  const _LoadingListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CommonShimmer(width: 140, height: 18),
                CommonShimmer(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            const CommonShimmer(width: 100, height: 26),
          ],
        ),
      ),
    );
  }
}

/// Giao diện rỗng khi người dùng chưa có nhóm nào
class _EmptyGroupView extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const _EmptyGroupView({required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapVerticalLg,
            const Text(
              'Chưa có nhóm chia tiền nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapVerticalSm,
            const Text(
              'Hãy tạo nhóm đầu tiên để mời bạn bè, quét hóa đơn AI và bắt đầu chia tiền sòng phẳng ngay hôm nay!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            AppSpacing.gapVerticalXl,
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: onCreateGroup,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Tạo nhóm ngay',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
