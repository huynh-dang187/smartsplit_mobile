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
import 'register_screen.dart';

/// Màn hình Đăng nhập tài khoản SmartSplit chuẩn Fintech Operate Mode.
class LoginScreen extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        authRepositories: getIt<IAuthRepositories>(),
      ),
      child: _LoginView(onLoginSuccess: onLoginSuccess),
    );
  }
}

class _LoginView extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const _LoginView({this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER & BRANDING ---
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.creditorBorder, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalLg,
                    Text(
                      'SmartSplit',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapVerticalXs,
                    const Text(
                      'Chia tiền nhóm & Quét hóa đơn AI tự động',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapVerticalXxl,

                    // --- FORM FIELDS ---
                    // Email
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapVerticalSm,
                    TextField(
                      controller: cubit.emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'vidu@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                    AppSpacing.gapVerticalLg,

                    // Mật khẩu
                    const Text(
                      'Mật khẩu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapVerticalSm,
                    TextField(
                      controller: cubit.passwordController,
                      obscureText: state.obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        _handleLogin(context, cubit);
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu của bạn',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            state.obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
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

                    // --- NÚT ĐĂNG NHẬP ---
                    CommonButton(
                      label: 'Đăng nhập',
                      isLoading: state.status.isLoading,
                      onPressed: () => _handleLogin(context, cubit),
                    ),
                    AppSpacing.gapVerticalLg,

                    // --- CHUYỂN SANG ĐĂNG KÝ ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(onRegisterSuccess: onLoginSuccess),
                              ),
                            );
                          },
                          child: const Text('Đăng ký ngay'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, AuthCubit cubit) {
    context.hideKeyboard();
    cubit.login(
      onSuccess: () {
        context.showSnackBar('Đăng nhập thành công!');
        onLoginSuccess?.call();
      },
      onError: (err) {
        context.showSnackBar(err, isError: true);
      },
    );
  }
}
