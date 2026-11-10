import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/common/constants/bank_bins.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/bank_info_model.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/cubit/app/app_cubit.dart';
import '../../domain/interfaces/i_auth_repositories.dart';

part 'auth_state.dart';

/// Cubit quản lý trạng thái và logic tương tác của Feature Auth.
class AuthCubit extends Cubit<AuthState> {
  final IAuthRepositories _authRepositories;

  // Quản lý các TextEditingController tập trung tại Cubit
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController accountNoController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();

  AuthCubit({
    required IAuthRepositories authRepositories,
  })  : _authRepositories = authRepositories,
        super(const AuthState());

  /// Chọn ngân hàng nhận tiền từ danh sách Napas
  void selectBank(BankOption bank) {
    emit(state.copyWith(selectedBank: bank));
  }

  /// Bật/tắt ẩn hiện mật khẩu
  void togglePasswordVisibility() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  /// Khởi tạo dữ liệu người dùng khi mở màn hình Hồ sơ & Tài khoản ngân hàng
  void initForProfile(UserModel user) {
    nameController.text = user.name;
    if (user.bankInfo != null) {
      accountNoController.text = user.bankInfo!.accountNo;
      accountNameController.text = user.bankInfo!.accountName;
      final matchedBank = BankBins.findByBin(user.bankInfo!.bankBin) ??
          BankBins.findByShortName(user.bankInfo!.bankShortName);
      emit(state.copyWith(
        user: user,
        selectedBank: matchedBank,
        status: BlocStatus.initial,
      ));
    } else {
      emit(state.copyWith(
        user: user,
        status: BlocStatus.initial,
      ));
    }
  }

  /// Đăng nhập tài khoản
  Future<void> login({
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      const msg = 'Vui lòng nhập địa chỉ email';
      emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
      onError?.call(msg);
      return;
    }

    if (password.isEmpty) {
      const msg = 'Vui lòng nhập mật khẩu';
      emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
      onError?.call(msg);
      return;
    }

    emit(state.copyWith(status: BlocStatus.loading, errorMessage: null));

    final result = await _authRepositories.login(
      email: email,
      password: password,
    );

    if (isClosed) return;

    if (result.isSuccess && result.data != null) {
      getIt<AppCubit>().updateCurrentUser(result.data!);
      emit(state.copyWith(
        status: BlocStatus.success,
        user: result.data,
      ));
      onSuccess?.call();
    } else {
      final errorMsg = result.message ?? 'Đăng nhập không thành công';
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: errorMsg,
      ));
      onError?.call(errorMsg);
    }
  }

  /// Đăng ký tài khoản mới kèm tài khoản ngân hàng (tùy chọn)
  Future<void> register({
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty) {
      const msg = 'Vui lòng nhập họ và tên của bạn';
      emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
      onError?.call(msg);
      return;
    }

    if (email.isEmpty) {
      const msg = 'Vui lòng nhập địa chỉ email';
      emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
      onError?.call(msg);
      return;
    }

    if (password.length < 6) {
      const msg = 'Mật khẩu phải có độ dài tối thiểu 6 ký tự';
      emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
      onError?.call(msg);
      return;
    }

    // Xử lý thông tin ngân hàng nếu người dùng có nhập
    BankInfoModel? bankInfo;
    final accountNo = accountNoController.text.trim();
    final accountName = accountNameController.text.trim();

    if (accountNo.isNotEmpty || accountName.isNotEmpty || state.selectedBank != null) {
      if (state.selectedBank == null) {
        const msg = 'Vui lòng chọn ngân hàng nhận tiền';
        emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
        onError?.call(msg);
        return;
      }

      if (accountNo.isEmpty) {
        const msg = 'Vui lòng nhập số tài khoản ngân hàng';
        emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
        onError?.call(msg);
        return;
      }

      if (accountName.isEmpty) {
        const msg = 'Vui lòng nhập tên chủ tài khoản ngân hàng';
        emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
        onError?.call(msg);
        return;
      }

      bankInfo = BankInfoModel(
        bankBin: state.selectedBank!.bin,
        bankShortName: state.selectedBank!.shortName,
        accountNo: accountNo,
        accountName: accountName.toUpperCase(),
      );
    }

    emit(state.copyWith(status: BlocStatus.loading, errorMessage: null));

    final result = await _authRepositories.register(
      name: name,
      email: email,
      password: password,
      bankInfo: bankInfo,
    );

    if (isClosed) return;

    if (result.isSuccess && result.data != null) {
      getIt<AppCubit>().updateCurrentUser(result.data!);
      emit(state.copyWith(
        status: BlocStatus.success,
        user: result.data,
      ));
      onSuccess?.call();
    } else {
      final errorMsg = result.message ?? 'Đăng ký không thành công';
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: errorMsg,
      ));
      onError?.call(errorMsg);
    }
  }

  /// Cập nhật thông tin ngân hàng Napas cho tài khoản
  Future<void> updateProfileBank({
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      const msg = 'Họ và tên không được để trống';
      emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
      onError?.call(msg);
      return;
    }

    BankInfoModel? bankInfo;
    final accountNo = accountNoController.text.trim();
    final accountName = accountNameController.text.trim();

    if (accountNo.isNotEmpty || accountName.isNotEmpty || state.selectedBank != null) {
      if (state.selectedBank == null) {
        const msg = 'Vui lòng chọn ngân hàng';
        emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
        onError?.call(msg);
        return;
      }

      if (accountNo.isEmpty) {
        const msg = 'Vui lòng nhập số tài khoản ngân hàng';
        emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
        onError?.call(msg);
        return;
      }

      if (accountName.isEmpty) {
        const msg = 'Vui lòng nhập tên chủ tài khoản (viết hoa)';
        emit(state.copyWith(status: BlocStatus.validateError, errorMessage: msg));
        onError?.call(msg);
        return;
      }

      bankInfo = BankInfoModel(
        bankBin: state.selectedBank!.bin,
        bankShortName: state.selectedBank!.shortName,
        accountNo: accountNo,
        accountName: accountName.toUpperCase(),
      );
    }

    emit(state.copyWith(status: BlocStatus.loading, errorMessage: null));

    final result = await _authRepositories.updateProfile(
      name: name,
      bankInfo: bankInfo,
    );

    if (isClosed) return;

    if (result.isSuccess && result.data != null) {
      getIt<AppCubit>().updateCurrentUser(result.data!);
      emit(state.copyWith(
        status: BlocStatus.success,
        user: result.data,
      ));
      onSuccess?.call();
    } else {
      final errorMsg = result.message ?? 'Cập nhật thông tin thất bại';
      emit(state.copyWith(
        status: BlocStatus.error,
        errorMessage: errorMsg,
      ));
      onError?.call(errorMsg);
    }
  }

  @override
  Future<void> close() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    accountNoController.dispose();
    accountNameController.dispose();
    return super.close();
  }
}
