import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/num_x.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_button.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_member_model.dart';

/// Thanh cố định ở đáy màn hình hiển thị số tiền tạm tính theo tỷ lệ Pro-rata của từng người và nút Lưu hóa đơn.
class MemberShareBottomBar extends StatelessWidget {
  final int calculatedTotal;
  final Map<String, int> realtimeMemberShares;
  final List<GroupMemberModel> groupMembers;
  final bool isLoading;
  final bool isValidToSubmit;
  final VoidCallback onSubmit;

  const MemberShareBottomBar({
    super.key,
    required this.calculatedTotal,
    required this.realtimeMemberShares,
    required this.groupMembers,
    required this.isLoading,
    required this.isValidToSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dòng hiển thị tóm tắt phần chia tiền Pro-rata của từng người
            if (groupMembers.isNotEmpty && realtimeMemberShares.isNotEmpty) ...[
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupMembers.length,
                  separatorBuilder: (_, __) => AppSpacing.gapHorizontalSm,
                  itemBuilder: (context, index) {
                    final member = groupMembers[index];
                    final share = realtimeMemberShares[member.memberId] ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${member.memberName}: ',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            share.toVnd(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Nút Lưu hóa đơn chính
            CommonButton(
              label: 'Lưu & Chia Hóa Đơn (${calculatedTotal.toVnd()})',
              icon: Icons.check_circle_rounded,
              isLoading: isLoading,
              onPressed: isValidToSubmit
                  ? () {
                      HapticFeedback.mediumImpact();
                      onSubmit();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
