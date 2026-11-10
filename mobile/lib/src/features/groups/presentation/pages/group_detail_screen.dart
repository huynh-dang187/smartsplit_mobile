import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/context_x.dart';
import 'package:smartsplit_mobile/src/common/extensions/num_x.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/cubit/app/app_cubit.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_error_view.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_loading.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/expense_model.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/pages/split_workspace_screen.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_model.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/simplified_debt_model.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_detail_cubit.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/widgets/add_member_bottom_sheet.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/widgets/group_balance_card.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/widgets/vietqr_bottom_sheet.dart';
import 'package:smartsplit_mobile/src/shared/router/app_router.dart';

/// Màn hình chi tiết một nhóm: Lịch sử hóa đơn, cấn trừ nợ và tính năng quét VietQR.
class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  final int initialTabIndex;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GroupDetailCubit>()
        ..fetchGroupDetail(groupId)
        ..changeTab(initialTabIndex),
      child: _GroupDetailView(groupId: groupId),
    );
  }
}

class _GroupDetailView extends StatelessWidget {
  final String groupId;

  const _GroupDetailView({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupDetailCubit>();
    final currentUserId = context.watch<AppCubit>().state.currentUser?.id ?? '';

    return BlocConsumer<GroupDetailCubit, GroupDetailState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.status == BlocStatus.error) {
          context.showSnackBar(state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        final group = state.group;
        final title = group?.name ?? 'Chi tiết nhóm';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'Thêm thành viên',
                icon: const Icon(Icons.person_add_outlined, size: 24),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  AddMemberBottomSheet.show(context, groupId: groupId, cubit: cubit);
                },
              ),
              IconButton(
                tooltip: 'Làm mới dữ liệu',
                icon: const Icon(Icons.refresh_rounded, size: 24),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  cubit.fetchGroupDetail(groupId);
                },
              ),
              AppSpacing.gapHorizontalXs,
            ],
          ),
          body: Builder(
            builder: (context) {
              if (state.status.isLoading && group == null) {
                return const _DetailShimmerLoading();
              }

              if (state.status.isError && group == null) {
                return CommonErrorView(
                  message: state.errorMessage ?? 'Không thể tải thông tin nhóm',
                  onRetry: () => cubit.fetchGroupDetail(groupId),
                );
              }

              if (group == null) {
                return const Center(child: Text('Không tìm thấy thông tin nhóm'));
              }

              final myBalance = state.getMyNetBalance(currentUserId);

              return RefreshIndicator(
                onRefresh: () => cubit.fetchGroupDetail(groupId),
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 90), // Khoảng trống cho FAB
                  children: [
                    // --- 1. THẺ SỐ DƯ NỢ CỦA BẠN TRONG NHÓM ---
                    GroupBalanceCard(
                      groupName: group.name,
                      netBalance: myBalance,
                      subtitle: '${group.members.length} thành viên • ${group.description ?? "Không có mô tả"}',
                      onTapSettle: () {
                        cubit.changeTab(1); // Chuyển thẳng sang Tab Cấn trừ nợ
                      },
                    ),

                    // --- 2. THANH CHUYỂN ĐỔI TAB (SEGMENTED TABS) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TabButton(
                                label: 'Hóa đơn (${state.expenses.length})',
                                isSelected: state.selectedTabIndex == 0,
                                icon: Icons.receipt_long_rounded,
                                onTap: () => cubit.changeTab(0),
                              ),
                            ),
                            AppSpacing.gapHorizontalXs,
                            Expanded(
                              child: _TabButton(
                                label: 'Cấn trừ nợ (${group.simplifiedDebts.length})',
                                isSelected: state.selectedTabIndex == 1,
                                icon: Icons.handshake_outlined,
                                onTap: () => cubit.changeTab(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- 3. NỘI DUNG THEO TAB ĐƯỢC CHỌN ---
                    if (state.selectedTabIndex == 0)
                      _ExpensesTabView(
                        expenses: state.expenses,
                        groupId: groupId,
                      )
                    else
                      _DebtsTabView(
                        debts: group.simplifiedDebts,
                        currentUserId: currentUserId,
                        groupName: group.name,
                        onSettleDebt: (debt) {
                          cubit.settleDebt(
                            groupId: groupId,
                            fromUserId: debt.fromUserId,
                            toUserId: debt.toUserId,
                            amount: debt.amount,
                            onSuccess: () {
                              context.showSnackBar('Đã gạch nợ thành công!');
                            },
                            onError: (err) {
                              context.showSnackBar(err, isError: true);
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (group != null) {
                _showAddExpenseOptions(context, group, cubit);
              }
            },
            backgroundColor: AppColors.aiAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: const Text(
              'Quét Hóa Đơn AI',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  void _showAddExpenseOptions(
    BuildContext context,
    GroupModel group,
    GroupDetailCubit cubit,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.roundedSheet,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Thêm hóa đơn chia tiền',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              AppSpacing.gapVerticalMd,
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.aiAccentLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.aiAccent),
                ),
                title: const Text('Chụp ảnh hóa đơn (Camera)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Gemini Vision AI tự bóc tách món và thuế VAT', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (photo != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SplitWorkspaceScreen(
                          groupId: group.id,
                          groupMembers: group.members,
                          imagePath: photo.path,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) cubit.fetchGroupDetail(group.id);
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Chọn ảnh từ Thư viện (Gallery)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Tải ảnh hóa đơn có sẵn từ máy', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (image != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SplitWorkspaceScreen(
                          groupId: group.id,
                          groupMembers: group.members,
                          imagePath: image.path,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) cubit.fetchGroupDetail(group.id);
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.textPrimary),
                ),
                title: const Text('Tạo hóa đơn nhập tay', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Tự gõ tên món và đơn giá', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SplitWorkspaceScreen(
                        groupId: group.id,
                        groupMembers: group.members,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) cubit.fetchGroupDetail(group.id);
                  });
                },
              ),
              AppSpacing.gapVerticalSm,
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút chuyển đổi Tab có hỗ trợ Haptic Feedback
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            AppSpacing.gapHorizontalXs,
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab 1: Danh sách các khoản chi & thanh toán nợ
class _ExpensesTabView extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final String groupId;

  const _ExpensesTabView({
    required this.expenses,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 36,
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapVerticalMd,
              const Text(
                'Chưa có hóa đơn nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              AppSpacing.gapVerticalXs,
              const Text(
                'Bấm nút "Quét Hóa Đơn AI" bên dưới để thêm hóa đơn ăn uống đầu tiên!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormatter = DateFormat('dd/MM/yyyy • HH:mm');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final isBill = expense.type == 'BILL';
        final paidName = expense.paidByName;
        final dateStr = expense.createdAt != null ? dateFormatter.format(expense.createdAt!) : '';

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Icon phân loại BILL / SETTLEMENT
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isBill
                      ? AppColors.primaryLight.withValues(alpha: 0.15)
                      : AppColors.creditorBg,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Icon(
                  isBill ? Icons.restaurant_rounded : Icons.handshake_outlined,
                  color: isBill ? AppColors.primary : AppColors.creditorGreen,
                  size: 22,
                ),
              ),
              AppSpacing.gapHorizontalMd,

              // Tiêu đề, người trả và thời gian
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      isBill ? '$paidName đã thanh toán' : 'Gạch nợ hoàn tất',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapHorizontalSm,

              // Số tiền
              Text(
                expense.totalAmount.toVnd(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isBill ? AppColors.textPrimary : AppColors.creditorGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tab 2: Danh sách cấn trừ nợ (Kết quả từ thuật toán Greedy)
class _DebtsTabView extends StatelessWidget {
  final List<SimplifiedDebtModel> debts;
  final String currentUserId;
  final String groupName;
  final Function(SimplifiedDebtModel debt) onSettleDebt;

  const _DebtsTabView({
    required this.debts,
    required this.currentUserId,
    required this.groupName,
    required this.onSettleDebt,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.creditorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 42,
                  color: AppColors.creditorGreen,
                ),
              ),
              AppSpacing.gapVerticalLg,
              const Text(
                'Tuyệt vời! Cả nhóm đã sòng phẳng',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.creditorGreen,
                ),
              ),
              AppSpacing.gapVerticalXs,
              const Text(
                'Hiện tại không có thành viên nào nợ tiền trong nhóm này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        final isMeDebtor = debt.fromUserId == currentUserId;
        final isMeCreditor = debt.toUserId == currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isMeDebtor ? AppColors.debtorBorder : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        children: [
                          TextSpan(
                            text: isMeDebtor ? 'Bạn' : debt.fromUserName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text: ' cần trả cho ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextSpan(
                            text: isMeCreditor ? 'Bạn' : debt.toUserName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    debt.amount.toVnd(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isMeDebtor ? AppColors.debtorRed : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // Nếu bản thân là người nợ: Hiển thị nút bấm Quét VietQR
              if (isMeDebtor) ...[
                AppSpacing.gapVerticalMd,
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      VietQrBottomSheet.show(
                        context,
                        debt: debt,
                        groupName: groupName,
                        onConfirmSettled: () => onSettleDebt(debt),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text(
                      'Quét VietQR & Thanh toán',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ] else if (isMeCreditor) ...[
                AppSpacing.gapVerticalSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.creditorBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Đang chờ nhận tiền',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.creditorText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Shimmer Skeleton hiển thị khi đang tải chi tiết nhóm
class _DetailShimmerLoading extends StatelessWidget {
  const _DetailShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const CommonShimmer(
            width: double.infinity,
            height: 130,
            borderRadius: AppSpacing.roundedLg,
          ),
          AppSpacing.gapVerticalLg,
          const CommonShimmer(
            width: double.infinity,
            height: 42,
            borderRadius: AppSpacing.roundedSm,
          ),
          AppSpacing.gapVerticalLg,
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    CommonShimmer(
                      width: 44,
                      height: 44,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    AppSpacing.gapHorizontalMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonShimmer(width: 140, height: 16),
                          AppSpacing.gapVerticalXs,
                          CommonShimmer(width: 90, height: 12),
                        ],
                      ),
                    ),
                    CommonShimmer(width: 70, height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
