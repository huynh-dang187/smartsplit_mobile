import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/context_x.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_button.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_detail_cubit.dart';

/// Modal Bottom Sheet thêm thành viên mới vào nhóm bằng Email.
class AddMemberBottomSheet extends StatefulWidget {
  final String groupId;
  final GroupDetailCubit cubit;

  const AddMemberBottomSheet({
    super.key,
    required this.groupId,
    required this.cubit,
  });

  /// Hàm tiện ích mở Bottom Sheet
  static Future<void> show(
    BuildContext context, {
    required String groupId,
    required GroupDetailCubit cubit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMemberBottomSheet(groupId: groupId, cubit: cubit),
    );
  }

  @override
  State<AddMemberBottomSheet> createState() => _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends State<AddMemberBottomSheet> {
  bool _isLoading = false;

  void _handleSubmit() {
    final email = widget.cubit.memberEmailController.text.trim();
    if (email.isEmpty) {
      context.showSnackBar('Vui lòng nhập địa chỉ email của thành viên', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    context.hideKeyboard();

    widget.cubit.addMember(
      widget.groupId,
      onSuccess: () {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pop(context);
        context.showSnackBar('Thêm thành viên thành công!');
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        context.showSnackBar(err, isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedSheet,
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: bottomInset + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AppSpacing.gapVerticalMd,

          // Tiêu đề
          Row(
            children: [
              const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
              AppSpacing.gapHorizontalSm,
              const Expanded(
                child: Text(
                  'Thêm thành viên vào nhóm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.border),
          AppSpacing.gapVerticalLg,

          const Text(
            'Email thành viên *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          AppSpacing.gapVerticalXs,
          TextField(
            controller: widget.cubit.memberEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            decoration: const InputDecoration(
              hintText: 'Ví dụ: banbe@gmail.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          AppSpacing.gapVerticalSm,
          const Text(
            'Lưu ý: Thành viên cần đăng ký tài khoản SmartSplit trước khi được thêm vào nhóm.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          AppSpacing.gapVerticalXl,

          // Nút thêm thành viên
          CommonButton(
            label: 'Thêm vào nhóm',
            isLoading: _isLoading,
            onPressed: () {
              HapticFeedback.lightImpact();
              _handleSubmit();
            },
          ),
        ],
      ),
    );
  }
}
