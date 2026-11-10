import 'package:flutter/material.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/num_x.dart';

/// Banner cảnh báo sai lệch tổng tiền khi Gemini Vision AI đọc số in đáy bill khác tổng món + phụ phí.
class DiscrepancyWarningBanner extends StatelessWidget {
  final int calculatedTotal;
  final int receiptTotalAmount;

  const DiscrepancyWarningBanner({
    super.key,
    required this.calculatedTotal,
    required this.receiptTotalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.warningBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.warningAmber.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warningAmber,
            size: 24,
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cảnh báo chênh lệch hóa đơn AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warningText,
                    fontSize: 14,
                  ),
                ),
                AppSpacing.gapVerticalXs,
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.warningText,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Tổng món cộng phụ phí ('),
                      TextSpan(
                        text: calculatedTotal.toVnd(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ') đang lệch so với số in trên bill ('),
                      TextSpan(
                        text: receiptTotalAmount.toVnd(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: '). Bạn có thể chạm vào từng món để điều chỉnh lại giá cho khớp.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
