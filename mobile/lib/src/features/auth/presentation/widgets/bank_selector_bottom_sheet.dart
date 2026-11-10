import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/constants/bank_bins.dart';

/// BottomSheet chọn ngân hàng thụ hưởng từ danh sách 10 ngân hàng Napas phổ biến.
class BankSelectorBottomSheet extends StatefulWidget {
  final BankOption? selectedBank;

  const BankSelectorBottomSheet({
    super.key,
    this.selectedBank,
  });

  /// Hàm tiện ích hiển thị BottomSheet
  static Future<BankOption?> show(BuildContext context, {BankOption? current}) {
    return showModalBottomSheet<BankOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BankSelectorBottomSheet(selectedBank: current),
    );
  }

  @override
  State<BankSelectorBottomSheet> createState() => _BankSelectorBottomSheetState();
}

class _BankSelectorBottomSheetState extends State<BankSelectorBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredBanks = popularVietnameseBanks.where((bank) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return bank.shortName.toLowerCase().contains(q) ||
          bank.name.toLowerCase().contains(q) ||
          bank.bin.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedSheet,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Tiêu đề
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Chọn ngân hàng nhận tiền',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 24),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                ),
              ],
            ),
          ),
          // Ô tìm kiếm ngân hàng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã ngân hàng (VD: VCB, MB)...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          AppSpacing.gapVerticalSm,
          const Divider(height: 1),
          // Danh sách ngân hàng
          Expanded(
            child: filteredBanks.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy ngân hàng phù hợp',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: filteredBanks.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final bank = filteredBanks[index];
                      final isSelected = widget.selectedBank?.bin == bank.bin;

                      return ListTile(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context, bank);
                        },
                        minVerticalPadding: AppSpacing.md,
                        leading: Container(
                          width: 52,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            bank.shortName,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          bank.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Mã BIN: ${bank.bin}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
