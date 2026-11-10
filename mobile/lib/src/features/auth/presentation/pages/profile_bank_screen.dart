import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/context_x.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/cubit/app/app_cubit.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_button.dart';
import '../../domain/interfaces/i_auth_repositories.dart';
import '../cubits/auth_cubit.dart';
import '../widgets/bank_selector_bottom_sheet.dart';

/// Màn hình Hồ sơ cá nhân & Cài đặt thông tin tài khoản ngân hàng VietQR.
class ProfileBankScreen extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onLogout;

  const ProfileBankScreen({
    super.key,
    this.user,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = user ?? getIt<AppCubit>().state.currentUser;

    return BlocProvider(
      create: (_) {
        final cubit = AuthCubit(authRepositories: getIt<IAuthRepositories>());
        if (currentUser != null) {
          cubit.initForProfile(currentUser);
        }
        return cubit;
      },
      child: _ProfileBankView(onLogout: onLogout),
    );
  }
}

class _ProfileBankView extends StatelessWidget {
  final VoidCallback? onLogout;

  const _ProfileBankView({this.onLogout});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ sơ & Tài khoản VietQR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final currentUser = state.user ?? getIt<AppCubit>().state.currentUser;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- AVATAR & THÔNG TIN CƠ BẢN ---
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primarySurface,
                          child: Text(
                            (currentUser?.name.isNotEmpty == true)
                                ? currentUser!.name.trim()[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        AppSpacing.gapVerticalSm,
                        Text(
                          currentUser?.name ?? 'Người dùng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          currentUser?.email ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapVerticalXl,

                  // --- FORM CẬP NHẬT TÊN ---
                  const Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  AppSpacing.gapVerticalXs,
                  TextField(
                    controller: cubit.nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  AppSpacing.gapVerticalLg,

                  // --- CÀI ĐẶT TÀI KHOẢN NGÂN HÀNG VIETQR ---
                  Container(
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
                            ),
                            AppSpacing.gapHorizontalSm,
                            const Expanded(
                              child: Text(
                                'Tài khoản nhận tiền VietQR',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapVerticalXs,
                        const Text(
                          'Khi bạn là chủ nợ trong các bill ăn uống, ứng dụng sẽ tự động sinh mã VietQR dựa trên thông tin ngân hàng dưới đây để bạn bè chuyển khoản.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                        AppSpacing.gapVerticalMd,

                        // Chọn ngân hàng
                        const Text('Ngân hàng thụ hưởng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        AppSpacing.gapVerticalXs,
                        InkWell(
                          onTap: () async {
                            context.hideKeyboard();
                            final selected = await BankSelectorBottomSheet.show(
                              context,
                              current: state.selectedBank,
                            );
                            if (selected != null) {
                              cubit.selectBank(selected);
                            }
                          },
                          borderRadius: AppSpacing.roundedMd,
                          child: Container(
                            height: AppSpacing.inputHeight,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_rounded, size: 20, color: AppColors.textSecondary),
                                AppSpacing.gapHorizontalMd,
                                Expanded(
                                  child: Text(
                                    state.selectedBank != null
                                        ? '${state.selectedBank!.shortName} - ${state.selectedBank!.name}'
                                        : 'Chọn ngân hàng Napas...',
                                    style: TextStyle(
                                      color: state.selectedBank != null ? AppColors.textPrimary : AppColors.textTertiary,
                                      fontSize: 14,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.gapVerticalMd,

                        // Số tài khoản
                        const Text('Số tài khoản ngân hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        AppSpacing.gapVerticalXs,
                        TextField(
                          controller: cubit.accountNoController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Nhập số tài khoản ngân hàng',
                            prefixIcon: Icon(Icons.credit_card_rounded, size: 20),
                          ),
                        ),
                        AppSpacing.gapVerticalMd,

                        // Tên chủ tài khoản
                        const Text('Tên chủ tài khoản (In hoa không dấu)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        AppSpacing.gapVerticalXs,
                        TextField(
                          controller: cubit.accountNameController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          onChanged: (val) {
                            cubit.accountNameController.value = TextEditingValue(
                              text: val.toUpperCase(),
                              selection: cubit.accountNameController.selection,
                            );
                          },
                          decoration: const InputDecoration(
                            hintText: 'Ví dụ: NGUYEN VAN A',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapVerticalXl,

                  // --- NÚT LƯU THÔNG TIN ---
                  CommonButton(
                    label: 'Lưu thông tin ngân hàng',
                    isLoading: state.status.isLoading,
                    icon: Icons.save_rounded,
                    onPressed: () {
                      context.hideKeyboard();
                      cubit.updateProfileBank(
                        onSuccess: () {
                          context.showSnackBar('Cập nhật thông tin thành công!');
                        },
                        onError: (err) {
                          context.showSnackBar(err, isError: true);
                        },
                      );
                    },
                  ),
                  AppSpacing.gapVerticalLg,

                  // --- NÚT ĐĂNG XUẤT ---
                  CommonButton.outline(
                    label: 'Đăng xuất',
                    icon: Icons.logout_rounded,
                    onPressed: () {
                      _confirmLogout(context);
                    },
                  ),
                  AppSpacing.gapVerticalXxl,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?'),
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.debtorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
              getIt<AppCubit>().logout();
              onLogout?.call();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
