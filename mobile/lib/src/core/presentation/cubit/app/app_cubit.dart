import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/enums/bloc_status.dart';
import '../../../infrastructure/datasources/local/secured_storage.dart';
import '../../../infrastructure/model/user_model.dart';

part 'app_state.dart';

/// Cubit quản lý trạng thái phiên đăng nhập và người dùng hiện tại toàn app.
class AppCubit extends Cubit<AppState> {
  final SecuredStorage _securedStorage;

  AppCubit({
    required SecuredStorage securedStorage,
  })  : _securedStorage = securedStorage,
        super(const AppState());

  /// Kiểm tra phiên làm việc khi khởi động ứng dụng
  Future<void> checkAuthSession() async {
    emit(state.copyWith(status: BlocStatus.loading));

    final hasToken = _securedStorage.hasToken();
    if (!hasToken) {
      if (isClosed) return;
      emit(state.copyWith(
        status: BlocStatus.initial,
        currentUser: null,
      ));
      return;
    }

    final cachedUser = _securedStorage.getUser();
    if (isClosed) return;

    if (cachedUser != null) {
      emit(state.copyWith(
        status: BlocStatus.hasData,
        currentUser: cachedUser,
      ));
    } else {
      emit(state.copyWith(
        status: BlocStatus.initial,
        currentUser: null,
      ));
    }
  }

  /// Cập nhật thông tin User hiện tại sau khi đăng nhập / chỉnh sửa profile
  Future<void> updateCurrentUser(UserModel user) async {
    await _securedStorage.saveUser(user);
    if (isClosed) return;
    emit(state.copyWith(
      status: BlocStatus.hasData,
      currentUser: user,
    ));
  }

  /// Đăng xuất: Xóa cache và đưa về màn hình chào/đăng nhập
  Future<void> logout() async {
    await _securedStorage.clearAll();
    if (isClosed) return;
    emit(const AppState(
      status: BlocStatus.initial,
      currentUser: null,
    ));
  }
}
