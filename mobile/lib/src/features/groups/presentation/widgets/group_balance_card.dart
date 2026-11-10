import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';

/// Card hiển thị số dư nợ của nhóm trong SmartSplit.
/// 
/// Chuẩn hóa theo quy chuẩn:
/// - Semantic Tokens: [AppColors] cho 3 trạng thái nợ (Creditor, Debtor, Settled).
/// - Nhịp điệu không gian & bo góc: [AppSpacing] (lưới 4/8/16dp, touch target >= 44dp).
/// - Flutter hiện đại: Dùng `.withValues(alpha: ...)` thay thế hoàn toàn `.withOpacity()`.
class GroupBalanceCard extends StatelessWidget {
  final String groupName;
  final int netBalance; // Tiền VNĐ số nguyên
  final VoidCallback onTapSettle;
  final VoidCallback? onTapCard;
  final String? subtitle;

  const GroupBalanceCard({
    super.key,
    required this.groupName,
    required this.netBalance,
    required this.onTapSettle,
    this.onTapCard,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isDebtor = netBalance < 0;

    final Color statusColor = AppColors.getDebtColor(netBalance);
    final Color statusBg = AppColors.getDebtBgColor(netBalance);
    final Color statusText = AppColors.getDebtTextColor(netBalance);
    final String statusLabel = AppColors.getDebtStatusText(netBalance);

    final cardContent = Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      AppSpacing.gapVerticalXs,
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapHorizontalSm,
              Container(
                padding: AppSpacing.badgePadding,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: AppSpacing.roundedPill,
                  border: Border.all(
                    color: AppColors.getDebtBorderColor(netBalance),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Text(
            currencyFormatter.format(netBalance.abs()),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: -0.5,
            ),
          ),
          if (isDebtor) ...[
            AppSpacing.gapVerticalLg,
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight, // Chuẩn touch target tối thiểu 48dp
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact(); // Xúc giác nhẹ theo chuẩn Impeccable
                  onTapSettle();
                },
                icon: const Icon(Icons.qr_code_rounded, size: 20),
                label: const Text(
                  'Thanh toán ngay qua VietQR',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
          ],
        ],
      ),
    );

    if (onTapCard != null) {
      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTapCard!();
        },
        borderRadius: AppSpacing.roundedLg,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
