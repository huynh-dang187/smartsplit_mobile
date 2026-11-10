import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/common/constants/app_colors.dart';
import 'package:smartsplit_mobile/src/common/constants/app_spacing.dart';
import 'package:smartsplit_mobile/src/common/extensions/context_x.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_button.dart';
import '../../domain/interfaces/i_auth_repositories.dart';
import '../cubits/auth_cubit.dart';
import '../widgets/bank_selector_bottom_sheet.dart';

/// Màn hình Đăng ký tài khoản kèm cấu hình tài khoản VietQR (tùy chọn).
class RegisterScreen extends StatelessWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({
    super.key,
    this.onRegisterSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        authRepositories: getIt<IAuthRepositories>(),
      ),
      child: _RegisterView(onRegisterSuccess: onRegisterSuccess),
    );
  }
}

class _RegisterView extends StatelessWidget {
  final VoidCallback? onRegisterSuccess;

  const _RegisterView({this.onRegisterSuccess});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- THÔNG TIN TÀI KHOẢN CƠ BẢN ---
                  const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  // Họ và tên
                  const Text('Họ và tên *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  AppSpacing.gapVerticalXs,
                  TextField(
                    controller: cubit.nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Nguyễn Văn A',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  // Email
                  const Text('Email *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  AppSpacing.gapVerticalXs,
                  TextField(
                    controller: cubit.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'vidu@gmail.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  // Mật khẩu
                  const Text('Mật khẩu *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  AppSpacing.gapVerticalXs,
                  TextField(
                    controller: cubit.passwordController,
                    obscureText: state.obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Tối thiểu 6 ký tự',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          state.obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: cubit.togglePasswordVisibility,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        constraints: const BoxConstraints(
                          minWidth: AppSpacing.minTouchTarget,
                          minHeight: AppSpacing.minTouchTarget,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalXl,

                  // --- KHU VỰC TÙY CHỌN TÀI KHOẢN NGÂN HÀNG VIETQR ---
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
                          'Cài đặt ngay hoặc bổ sung sau. Dùng để tạo mã QR chuyển khoản tự động khi bạn là chủ nợ.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                        AppSpacing.gapVerticalMd,

                        // Chọn ngân hàng
                        const Text('Ngân hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                        const Text('Số tài khoản', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        AppSpacing.gapVerticalXs,
                        TextField(
                          controller: cubit.accountNoController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Ví dụ: 1029384756',
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

                  // --- NÚT ĐĂNG KÝ ---
                  CommonButton(
                    label: 'Đăng ký tài khoản',
                    isLoading: state.status.isLoading,
                    onPressed: () => _handleRegister(context, cubit),
                  ),
                  AppSpacing.gapVerticalMd,

                  // Quay lại đăng nhập
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                  AppSpacing.gapVerticalLg,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleRegister(BuildContext context, AuthCubit cubit) {
    context.hideKeyboard();
    cubit.register(
      onSuccess: () {
        context.showSnackBar('Đăng ký tài khoản thành công!');
        Navigator.pop(context);
        onRegisterSuccess?.call();
      },
      onError: (err) {
        context.showSnackBar(err, isError: true);
      },
    );
  }
}
