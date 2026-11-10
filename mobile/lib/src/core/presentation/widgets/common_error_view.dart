import 'package:flutter/material.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'common_button.dart';

/// Khung hiển thị thông báo lỗi thân thiện kèm nút "Thử lại" (chuẩn Impeccable Harden).
class CommonErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const CommonErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.debtorBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.debtorBorder),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.debtorRed,
              ),
            ),
            AppSpacing.gapVerticalLg,
            const Text(
              'Đã xảy ra sự cố',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              message ?? 'Không thể tải dữ liệu vào lúc này. Vui lòng kiểm tra lại kết nối.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapVerticalXl,
              SizedBox(
                width: 160,
                child: CommonButton(
                  label: 'Thử lại',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
