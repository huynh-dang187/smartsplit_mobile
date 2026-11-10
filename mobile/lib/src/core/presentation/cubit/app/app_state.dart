part of 'app_cubit.dart';

/// Trạng thái ứng dụng toàn cục (Authentication & Current User).
final class AppState {
  final BlocStatus status;
  final UserModel? currentUser;
  final String? errorMessage;

  const AppState({
    this.status = BlocStatus.initial,
    this.currentUser,
    this.errorMessage,
  });

  /// Kiểm tra xem người dùng đã đăng nhập thành công hay chưa
  bool get isAuthenticated => currentUser != null;

  AppState copyWith({
    BlocStatus? status,
    UserModel? currentUser,
    String? errorMessage,
  }) {
    return AppState(
      status: status ?? this.status,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
