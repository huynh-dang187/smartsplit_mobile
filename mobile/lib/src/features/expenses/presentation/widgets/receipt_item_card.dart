import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/num_x.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/models/parsed_receipt_model.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/group_member_model.dart';

/// Card đại diện cho một món ăn trong hóa đơn kèm tính năng gán người ăn (Interactive Member Assignment).
class ReceiptItemCard extends StatelessWidget {
  final ParsedReceiptItemModel item;
  final List<String> assignedMemberIds;
  final List<GroupMemberModel> groupMembers;
  final Function(String userId) onToggleMember;
  final VoidCallback onSelectAllMembers;
  final Function(String name, double quantity, int unitPrice) onEditItem;
  final VoidCallback onDeleteItem;

  const ReceiptItemCard({
    super.key,
    required this.item,
    required this.assignedMemberIds,
    required this.groupMembers,
    required this.onToggleMember,
    required this.onSelectAllMembers,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(
      text: item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
    );
    final priceCtrl = TextEditingController(text: item.unitPrice.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa món ăn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên món'),
              ),
              AppSpacing.gapVerticalMd,
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Số lượng'),
              ),
              AppSpacing.gapVerticalMd,
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Đơn giá (VNĐ)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newQty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
              final newPrice = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? item.unitPrice;

              if (newName.isNotEmpty && newPrice >= 0) {
                onEditItem(newName, newQty > 0 ? newQty : 1.0, newPrice);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = groupMembers.isNotEmpty &&
        groupMembers.every((m) => assignedMemberIds.contains(m.memberId));

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: assignedMemberIds.isEmpty ? AppColors.debtorBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng tiêu đề món + đơn giá + nút xóa/sửa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} x ${item.unitPrice.toVnd()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapHorizontalSm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.totalPrice.toVnd(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        tooltip: 'Sửa món',
                        onPressed: () => _showEditDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.debtorRed),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        tooltip: 'Xóa món',
                        onPressed: onDeleteItem,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 12, color: AppColors.border),

          // Hàng gán thành viên ăn món này
          Row(
            children: [
              const Text(
                'Ai ăn món này:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Nút chọn cả nhóm
              InkWell(
                onTap: onSelectAllMembers,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAllSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Cả nhóm (${groupMembers.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAllSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,

          // Danh sách Chips thành viên
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: groupMembers.map((member) {
              final isSelected = assignedMemberIds.contains(member.memberId);

              return InkWell(
                onTap: () => onToggleMember(member.memberId),
                borderRadius: AppSpacing.roundedPill,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: AppSpacing.roundedPill,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      AppSpacing.gapHorizontalXs,
                      Text(
                        member.memberName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (assignedMemberIds.isEmpty) ...[
            AppSpacing.gapVerticalXs,
            const Text(
              '⚠️ Chưa có ai ăn món này! Hãy chọn ít nhất 1 người.',
              style: TextStyle(fontSize: 11, color: AppColors.debtorRed, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
