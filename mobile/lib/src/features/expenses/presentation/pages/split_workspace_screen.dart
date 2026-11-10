import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/context_x.dart';
import 'package:smartsplit_mobile/src/common/extensions/num_x.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/cubit/app/app_cubit.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_error_view.dart';
import 'package:smartsplit_mobile/src/features/expenses/domain/interfaces/i_expense_repositories.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/cubits/split_workspace_cubit.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/widgets/discrepancy_warning_banner.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/widgets/member_share_bottom_bar.dart';
import 'package:smartsplit_mobile/src/features/expenses/presentation/widgets/receipt_item_card.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_member_model.dart';

/// Màn hình không gian làm việc chia tiền hóa đơn bóc tách bởi Gemini Vision AI.
class SplitWorkspaceScreen extends StatelessWidget {
  final String groupId;
  final List<GroupMemberModel> groupMembers;
  final String? imagePath;

  const SplitWorkspaceScreen({
    super.key,
    required this.groupId,
    required this.groupMembers,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AppCubit>().state.currentUser?.id ?? '';
    final memberIds = groupMembers.map((m) => m.memberId).toList();

    return BlocProvider(
      create: (_) {
        final cubit = SplitWorkspaceCubit(
          expenseRepositories: getIt<IExpenseRepositories>(),
        );

        if (imagePath != null && imagePath!.isNotEmpty) {
          cubit.scanReceiptImage(
            imagePath!,
            memberIds,
            currentUserId: currentUserId,
          );
        } else {
          cubit.initManualBill(memberIds, currentUserId);
        }

        return cubit;
      },
      child: _SplitWorkspaceView(
        groupId: groupId,
        groupMembers: groupMembers,
      ),
    );
  }
}

class _SplitWorkspaceView extends StatefulWidget {
  final String groupId;
  final List<GroupMemberModel> groupMembers;

  const _SplitWorkspaceView({
    required this.groupId,
    required this.groupMembers,
  });

  @override
  State<_SplitWorkspaceView> createState() => _SplitWorkspaceViewState();
}

class _SplitWorkspaceViewState extends State<_SplitWorkspaceView> {
  late final TextEditingController _titleController;
  late final TextEditingController _taxController;
  late final TextEditingController _serviceController;
  late final TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _taxController = TextEditingController(text: '0');
    _serviceController = TextEditingController(text: '0');
    _discountController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taxController.dispose();
    _serviceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _syncControllersWithState(SplitWorkspaceState state) {
    if (_titleController.text.isEmpty && state.title.isNotEmpty) {
      _titleController.text = state.title;
    }
    if (_taxController.text == '0' && state.extraCharges.tax > 0) {
      _taxController.text = state.extraCharges.tax.toString();
    }
    if (_serviceController.text == '0' && state.extraCharges.serviceCharge > 0) {
      _serviceController.text = state.extraCharges.serviceCharge.toString();
    }
    if (_discountController.text == '0' && state.extraCharges.discount > 0) {
      _discountController.text = state.extraCharges.discount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SplitWorkspaceCubit>();
    final memberIds = widget.groupMembers.map((m) => m.memberId).toList();

    return BlocConsumer<SplitWorkspaceCubit, SplitWorkspaceState>(
      listener: (context, state) {
        _syncControllersWithState(state);

        if (state.status == BlocStatus.error && state.errorMessage != null) {
          context.showSnackBar(state.errorMessage!, isError: true);
        }
      },
      builder: (context, state) {
        // --- 1. TRẠNG THÁI AI ĐANG QUÉT ẢNH HÓA ĐƠN ---
        if (state.status.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Bóc tách hóa đơn AI')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.aiAccentLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 46,
                        color: AppColors.aiAccent,
                      ),
                    ),
                    AppSpacing.gapVerticalLg,
                    const Text(
                      'Gemini Vision AI đang đọc hóa đơn...',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapVerticalSm,
                    const Text(
                      'Hệ thống đang tự động lọc món ăn, đơn giá, thuế VAT và chuyển về số nguyên VNĐ...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    AppSpacing.gapVerticalXl,
                    const SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.aiAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // --- 2. TRẠNG THÁI LỖI ---
        if (state.status.isError && state.items.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lỗi quét hóa đơn')),
            body: CommonErrorView(
              message: state.errorMessage ?? 'Không thể bóc tách hóa đơn này',
              onRetry: () => Navigator.pop(context),
            ),
          );
        }

        // --- 3. GIAO DIỆN CHIA TIỀN CHÍNH (WORKSPACE) ---
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Chia tiền hóa đơn',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'Thêm món',
                icon: const Icon(Icons.add_rounded, size: 26),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => cubit.addBlankItem(memberIds),
              ),
              AppSpacing.gapHorizontalXs,
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
                  children: [
                    // Tên hóa đơn & Người trả tiền
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tên hóa đơn',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          AppSpacing.gapVerticalXs,
                          TextField(
                            controller: _titleController,
                            textInputAction: TextInputAction.done,
                            onChanged: (val) => cubit.updateTitle(val),
                            decoration: const InputDecoration(
                              hintText: 'Ví dụ: Cơm trưa, Lẩu Haidilao...',
                              prefixIcon: Icon(Icons.receipt_rounded, size: 20),
                            ),
                          ),
                          AppSpacing.gapVerticalMd,

                          // Người trả tiền (Payer)
                          const Text(
                            'Ai là người thanh toán hóa đơn này?',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          AppSpacing.gapVerticalXs,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: AppSpacing.roundedSm,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: state.paidByUserId.isNotEmpty ? state.paidByUserId : null,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                items: widget.groupMembers.map((member) {
                                  return DropdownMenuItem<String>(
                                    value: member.memberId,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                                        AppSpacing.gapHorizontalSm,
                                        Expanded(
                                          child: Text(
                                            member.memberName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    cubit.changePayer(newVal);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cảnh báo sai lệch tiền AI (nếu có)
                    if (state.isDiscrepancy) ...[
                      DiscrepancyWarningBanner(
                        calculatedTotal: state.calculatedTotal,
                        receiptTotalAmount: state.receiptTotalAmount,
                      ),
                    ],

                    AppSpacing.gapVerticalSm,

                    // Danh sách món ăn
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DANH SÁCH MÓN ĂN (${state.items.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => cubit.addBlankItem(memberIds),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Thêm món', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                    ...state.items.map((item) {
                      final assigned = state.itemAssignments[item.id] ?? item.assignedTo;
                      return ReceiptItemCard(
                        item: item,
                        assignedMemberIds: assigned,
                        groupMembers: widget.groupMembers,
                        onToggleMember: (userId) => cubit.toggleMemberForItem(item.id, userId),
                        onSelectAllMembers: () => cubit.selectAllMembersForItem(item.id, memberIds),
                        onEditItem: (name, qty, price) => cubit.updateItem(
                          itemId: item.id,
                          name: name,
                          quantity: qty,
                          unitPrice: price,
                        ),
                        onDeleteItem: () => cubit.removeItem(item.id),
                      );
                    }),

                    AppSpacing.gapVerticalMd,

                    // Khối phụ phí & Giảm giá
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phụ phí & Giảm giá (Tùy chọn)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          AppSpacing.gapVerticalMd,
                          _buildChargeField(
                            label: 'Thuế VAT (VNĐ)',
                            controller: _taxController,
                            icon: Icons.percent_rounded,
                            onChanged: (val) {
                              final numVal = int.tryParse(val.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                              cubit.updateExtraCharges(tax: numVal);
                            },
                          ),
                          AppSpacing.gapVerticalSm,
                          _buildChargeField(
                            label: 'Phí phục vụ (VNĐ)',
                            controller: _serviceController,
                            icon: Icons.room_service_outlined,
                            onChanged: (val) {
                              final numVal = int.tryParse(val.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                              cubit.updateExtraCharges(serviceCharge: numVal);
                            },
                          ),
                          AppSpacing.gapVerticalSm,
                          _buildChargeField(
                            label: 'Giảm giá / Voucher (VNĐ)',
                            controller: _discountController,
                            icon: Icons.discount_outlined,
                            onChanged: (val) {
                              final numVal = int.tryParse(val.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                              cubit.updateExtraCharges(discount: numVal);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Tóm tắt tổng tiền hóa đơn
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Tiền món ăn', state.subtotalAmount.toVnd()),
                          if (state.netExtraCharges != 0) ...[
                            AppSpacing.gapVerticalXs,
                            _buildSummaryRow('Phụ phí ròng', state.netExtraCharges.toSignedVnd()),
                          ],
                          const Divider(height: 16, color: AppColors.border),
                          _buildSummaryRow(
                            'Tổng cộng thanh toán',
                            state.calculatedTotal.toVnd(),
                            bold: true,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Thanh chia tiền cố định ở đáy
              MemberShareBottomBar(
                calculatedTotal: state.calculatedTotal,
                realtimeMemberShares: state.realtimeMemberShares,
                groupMembers: widget.groupMembers,
                isLoading: state.status == BlocStatus.checking,
                isValidToSubmit: state.isValidToSubmit,
                onSubmit: () {
                  cubit.submitExpense(
                    widget.groupId,
                    onSuccess: () {
                      context.showSnackBar('Đã lưu hóa đơn và chia tiền thành công!');
                      Navigator.pop(context, true);
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
    );
  }

  Widget _buildChargeField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        AppSpacing.gapHorizontalSm,
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              onChanged: onChanged,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool bold = false,
    Color color = AppColors.textPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
