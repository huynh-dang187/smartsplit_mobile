part of 'auth_cubit.dart';

/// Trạng thái của AuthCubit phục vụ cho màn hình Đăng nhập, Đăng ký và Cập nhật ngân hàng.
final class AuthState {
  final BlocStatus status;
  final UserModel? user;
  final BankOption? selectedBank;
  final String? errorMessage;
  final bool obscurePassword;

  const AuthState({
    this.status = BlocStatus.initial,
    this.user,
    this.selectedBank,
    this.errorMessage,
    this.obscurePassword = true,
  });

  AuthState copyWith({
    BlocStatus? status,
    UserModel? user,
    BankOption? selectedBank,
    String? errorMessage,
    bool? obscurePassword,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      selectedBank: selectedBank ?? this.selectedBank,
      errorMessage: errorMessage ?? this.errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}
