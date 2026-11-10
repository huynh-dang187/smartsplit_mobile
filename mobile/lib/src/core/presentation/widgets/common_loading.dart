import 'package:flutter/material.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';

/// Hiệu ứng Shimmer Skeleton mượt mà thay thế Spinner trơ trọi (chuẩn Impeccable).
class CommonShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const CommonShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppSpacing.roundedMd,
  });

  /// Shimmer hình tròn cho Avatar
  const CommonShimmer.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = AppSpacing.roundedPill;

  @override
  State<CommonShimmer> createState() => _CommonShimmerState();
}

class _CommonShimmerState extends State<CommonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                AppColors.surfaceVariant,
                AppColors.borderLight,
                AppColors.surfaceVariant,
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton Card mẫu hiển thị khi đang tải danh sách hóa đơn/nhóm
class CommonCardSkeleton extends StatelessWidget {
  const CommonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonShimmer(width: MediaQuery.sizeOf(context).width * 0.45, height: 20),
              const CommonShimmer(width: 80, height: 24, borderRadius: AppSpacing.roundedPill),
            ],
          ),
          AppSpacing.gapVerticalMd,
          CommonShimmer(width: MediaQuery.sizeOf(context).width * 0.3, height: 28),
        ],
      ),
    );
  }
}
