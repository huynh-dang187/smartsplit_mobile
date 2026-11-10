import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/context_x.dart';
import 'package:smartsplit_mobile/src/common/utils/currency_formatter.dart';
import 'package:smartsplit_mobile/src/common/utils/vietqr_helper.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_button.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_loading.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/models/simplified_debt_model.dart';

/// Modal Bottom Sheet hiển thị mã VietQR phục vụ thanh toán nợ trong nhóm.
/// 
/// Tuân thủ chuẩn UI-UX Pro Max & Impeccable:
/// - Bo tròn 2 góc trên 24dp.
/// - Kiểm tra an toàn `toUserBankInfo`: Nếu có sẽ sinh ảnh VietQR chuẩn Napas qua [VietQrHelper].
/// - Có nút sao chép nhanh số tài khoản kèm thông báo phản hồi xúc giác.
/// - Nút "Tôi đã chuyển khoản xong" có chiều cao >= 48dp, vùng chạm tối ưu.
class VietQrBottomSheet extends StatelessWidget {
  final SimplifiedDebtModel debt;
  final String groupName;
  final VoidCallback onConfirmSettled;

  const VietQrBottomSheet({
    super.key,
    required this.debt,
    required this.groupName,
    required this.onConfirmSettled,
  });

  /// Hàm tiện ích hiển thị BottomSheet
  static Future<void> show(
    BuildContext context, {
    required SimplifiedDebtModel debt,
    required String groupName,
    required VoidCallback onConfirmSettled,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VietQrBottomSheet(
        debt: debt,
        groupName: groupName,
        onConfirmSettled: onConfirmSettled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankInfo = debt.toUserBankInfo;
    final hasBankInfo = bankInfo != null && bankInfo.accountNo.isNotEmpty;

    final String qrUrl = hasBankInfo
        ? VietQrHelper.generateQrUrl(
            bankBin: bankInfo.bankBin,
            accountNo: bankInfo.accountNo,
            amount: debt.amount,
            accountName: bankInfo.accountName,
            fromUserName: debt.fromUserName,
            groupName: groupName,
          )
        : '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedSheet,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạt Drag handle
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

            // Tiêu đề BottomSheet & nút đóng
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 26),
                  AppSpacing.gapHorizontalSm,
                  const Expanded(
                    child: Text(
                      'Thanh toán chuyển khoản VietQR',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Nội dung cuộn
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- THẺ HIỂN THỊ MÃ QR HOẶC CẢNH BÁO CHƯA CÓ NGÂN HÀNG ---
                    if (hasBankInfo) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CachedNetworkImage(
                            imageUrl: qrUrl,
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(
                              width: 250,
                              height: 250,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CommonShimmer(width: 200, height: 200),
                                    AppSpacing.gapVerticalSm,
                                    Text(
                                      'Đang tạo mã VietQR...',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 250,
                              height: 250,
                              color: AppColors.surfaceVariant,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textSecondary),
                                  AppSpacing.gapVerticalSm,
                                  Text(
                                    'Không thể tải ảnh mã QR',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapVerticalLg,

                      // Thông tin chi tiết người nhận
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              label: 'Người nhận',
                              value: debt.toUserName,
                              bold: true,
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            _buildInfoRow(
                              label: 'Ngân hàng',
                              value: bankInfo.bankShortName,
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Số tài khoản',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      bankInfo.accountNo,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    AppSpacing.gapHorizontalXs,
                                    InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Clipboard.setData(ClipboardData(text: bankInfo.accountNo));
                                        context.showSnackBar('Đã sao chép số tài khoản');
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: AppColors.border),
                            _buildInfoRow(
                              label: 'Số tiền chuyển',
                              value: CurrencyFormatter.formatVnd(debt.amount),
                              valueColor: AppColors.creditorGreen,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Trường hợp chủ nợ chưa cài đặt ngân hàng
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.warningBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.warningText, size: 24),
                            AppSpacing.gapHorizontalMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${debt.toUserName} chưa cài đặt VietQR',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warningText,
                                      fontSize: 14,
                                    ),
                                  ),
                                  AppSpacing.gapVerticalXs,
                                  const Text(
                                    'Thành viên này chưa thêm tài khoản ngân hàng nhận tiền. Bạn có thể nhắc nhở họ cập nhật trong mục Hồ sơ, hoặc thanh toán trực tiếp bằng tiền mặt.',
                                    style: TextStyle(
                                      color: AppColors.warningText,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVerticalLg,
                      // Thẻ số tiền
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _buildInfoRow(
                          label: 'Số tiền cần trả',
                          value: CurrencyFormatter.formatVnd(debt.amount),
                          valueColor: AppColors.debtorRed,
                          bold: true,
                        ),
                      ),
                    ],

                    AppSpacing.gapVerticalXl,

                    // Nút xác nhận thanh toán nợ
                    CommonButton(
                      label: 'Tôi đã chuyển khoản xong',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        onConfirmSettled();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color valueColor = AppColors.textPrimary,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
