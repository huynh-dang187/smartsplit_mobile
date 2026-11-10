import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/context_x.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_button.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_list_cubit.dart';

/// Modal Bottom Sheet tạo nhóm chia tiền mới.
class CreateGroupBottomSheet extends StatefulWidget {
  final GroupListCubit cubit;

  const CreateGroupBottomSheet({
    super.key,
    required this.cubit,
  });

  /// Hàm tiện ích mở Bottom Sheet
  static Future<void> show(BuildContext context, {required GroupListCubit cubit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGroupBottomSheet(cubit: cubit),
    );
  }

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  bool _isLoading = false;

  void _handleSubmit() {
    final name = widget.cubit.nameController.text.trim();
    if (name.isEmpty) {
      context.showSnackBar('Vui lòng nhập tên nhóm', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    context.hideKeyboard();

    widget.cubit.createGroup(
      onSuccess: () {
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pop(context);
        context.showSnackBar('Tạo nhóm mới thành công!');
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
              const Icon(Icons.group_add_rounded, color: AppColors.primary, size: 24),
              AppSpacing.gapHorizontalSm,
              const Expanded(
                child: Text(
                  'Tạo nhóm chia tiền mới',
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

          // Ô nhập tên nhóm
          const Text(
            'Tên nhóm *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          AppSpacing.gapVerticalXs,
          TextField(
            controller: widget.cubit.nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Ăn trưa công ty, Đi du lịch Đà Lạt...',
              prefixIcon: Icon(Icons.groups_outlined, size: 20),
            ),
          ),
          AppSpacing.gapVerticalMd,

          // Ô nhập mô tả
          const Text(
            'Mô tả nhóm (Tùy chọn)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          AppSpacing.gapVerticalXs,
          TextField(
            controller: widget.cubit.descriptionController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Nhóm chia tiền ăn trưa hàng ngày',
              prefixIcon: Icon(Icons.notes_rounded, size: 20),
            ),
          ),
          AppSpacing.gapVerticalXl,

          // Nút tạo nhóm
          CommonButton(
            label: 'Tạo nhóm ngay',
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
