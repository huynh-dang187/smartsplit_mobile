import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsplit_mobile/src/common/constants/bank_bins.dart';
import 'package:smartsplit_mobile/src/core/domain/entities/base_result.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/bank_info_model.dart';
import 'package:smartsplit_mobile/src/core/infrastructure/model/user_model.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/features/auth/domain/interfaces/i_auth_repositories.dart';
import 'package:smartsplit_mobile/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:smartsplit_mobile/src/features/auth/presentation/pages/login_screen.dart';
import 'package:smartsplit_mobile/src/features/auth/presentation/pages/profile_bank_screen.dart';
import 'package:smartsplit_mobile/src/features/auth/presentation/pages/register_screen.dart';

/// Fake repository phục vụ kiểm thử đơn vị Auth
class FakeAuthRepository implements IAuthRepositories {
  bool shouldSucceed = true;
  String? mockErrorMessage;

  @override
  Future<BaseResult<UserModel>> login({
    required String email,
    required String password,
  }) async {
    if (shouldSucceed) {
      return BaseResult.ok(
        UserModel(id: 'user_1', name: 'Nguyễn Văn A', email: email),
        message: 'Đăng nhập thành công',
      );
    }
    return BaseResult.fail(
      mockErrorMessage ?? 'Tài khoản hoặc mật khẩu không chính xác',
    );
  }

  @override
  Future<BaseResult<UserModel>> register({
    required String name,
    required String email,
    required String password,
    BankInfoModel? bankInfo,
  }) async {
    if (shouldSucceed) {
      return BaseResult.ok(
        UserModel(
          id: 'user_new',
          name: name,
          email: email,
          bankInfo: bankInfo,
        ),
        message: 'Đăng ký thành công',
      );
    }
    return BaseResult.fail(mockErrorMessage ?? 'Email đã tồn tại');
  }

  @override
  Future<BaseResult<UserModel>> updateProfile({
    String? name,
    String? avatarUrl,
    BankInfoModel? bankInfo,
  }) async {
    if (shouldSucceed) {
      return BaseResult.ok(
        UserModel(
          id: 'user_updated',
          name: name ?? 'Cập nhật',
          email: 'test@gmail.com',
          bankInfo: bankInfo,
        ),
        message: 'Cập nhật thành công',
      );
    }
    return BaseResult.fail(mockErrorMessage ?? 'Lỗi cập nhật');
  }
}

void main() {
  late FakeAuthRepository fakeRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await initDependencies();

    fakeRepo = FakeAuthRepository();
    // Thay thế IAuthRepositories bằng Fake Repo trong GetIt
    getIt.unregister<IAuthRepositories>();
    getIt.registerSingleton<IAuthRepositories>(fakeRepo);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('AuthCubit Unit Tests', () {
    test('Khởi tạo ban đầu với trạng thái initial và controllers rỗng', () {
      final cubit = AuthCubit(authRepositories: fakeRepo);
      expect(cubit.state.status, BlocStatus.initial);
      expect(cubit.state.user, isNull);
      expect(cubit.state.selectedBank, isNull);
      expect(cubit.state.obscurePassword, isTrue);
      cubit.close();
    });

    test('selectBank cập nhật selectedBank chính xác trong state', () {
      final cubit = AuthCubit(authRepositories: fakeRepo);
      final bank = BankBins.supportedBanks[0]; // VCB

      cubit.selectBank(bank);
      expect(cubit.state.selectedBank?.shortName, 'VCB');
      expect(cubit.state.selectedBank?.bin, '970436');
      cubit.close();
    });

    test('togglePasswordVisibility bật/tắt cờ obscurePassword', () {
      final cubit = AuthCubit(authRepositories: fakeRepo);
      expect(cubit.state.obscurePassword, isTrue);

      cubit.togglePasswordVisibility();
      expect(cubit.state.obscurePassword, isFalse);

      cubit.togglePasswordVisibility();
      expect(cubit.state.obscurePassword, isTrue);
      cubit.close();
    });

    test('login thất bại và báo lỗi validateError khi để trống email hoặc mật khẩu', () async {
      final cubit = AuthCubit(authRepositories: fakeRepo);
      String? caughtError;

      // Email trống
      await cubit.login(onError: (err) => caughtError = err);
      expect(cubit.state.status, BlocStatus.validateError);
      expect(caughtError, contains('nhập địa chỉ email'));

      // Có email nhưng mật khẩu trống
      cubit.emailController.text = 'test@gmail.com';
      await cubit.login(onError: (err) => caughtError = err);
      expect(cubit.state.status, BlocStatus.validateError);
      expect(caughtError, contains('nhập mật khẩu'));

      cubit.close();
    });

    test('login thành công chuyển sang trạng thái success và gọi onSuccess', () async {
      final cubit = AuthCubit(authRepositories: fakeRepo);
      cubit.emailController.text = 'an@gmail.com';
      cubit.passwordController.text = '123456';

      bool isSuccessCalled = false;
      await cubit.login(onSuccess: () => isSuccessCalled = true);

      expect(cubit.state.status, BlocStatus.success);
      expect(cubit.state.user?.name, 'Nguyễn Văn A');
      expect(isSuccessCalled, isTrue);
      cubit.close();
    });

    test('register kiểm tra độ dài mật khẩu >= 6 ký tự', () async {
      final cubit = AuthCubit(authRepositories: fakeRepo);
      cubit.nameController.text = 'Lê B';
      cubit.emailController.text = 'b@gmail.com';
      cubit.passwordController.text = '123'; // < 6 ký tự

      String? caughtError;
      await cubit.register(onError: (err) => caughtError = err);

      expect(cubit.state.status, BlocStatus.validateError);
      expect(caughtError, contains('tối thiểu 6 ký tự'));
      cubit.close();
    });

    test('initForProfile nạp đúng thông tin tài khoản và ngân hàng', () {
      final cubit = AuthCubit(authRepositories: fakeRepo);
      const user = UserModel(
        id: 'u1',
        name: 'Trần Văn C',
        email: 'c@gmail.com',
        bankInfo: BankInfoModel(
          bankBin: '970422',
          bankShortName: 'MB',
          accountNo: '0987654321',
          accountName: 'TRAN VAN C',
        ),
      );

      cubit.initForProfile(user);

      expect(cubit.nameController.text, 'Trần Văn C');
      expect(cubit.accountNoController.text, '0987654321');
      expect(cubit.accountNameController.text, 'TRAN VAN C');
      expect(cubit.state.selectedBank?.shortName, 'MB');
      cubit.close();
    });
  });

  group('Auth Feature UI Render & Overflow Protection Tests', () {
    testWidgets('LoginScreen render đầy đủ các trường và không bị lỗi overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SmartSplit'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Đăng ký ngay'), findsOneWidget);
    });

    testWidgets('RegisterScreen render đầy đủ và mở được BottomSheet ngân hàng', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đăng ký tài khoản'), findsWidgets);
      expect(find.text('Thông tin cá nhân'), findsOneWidget);
      expect(find.text('Tài khoản nhận tiền VietQR'), findsOneWidget);

      // Bấm vào ô chọn ngân hàng để mở BottomSheet
      await tester.tap(find.text('Chọn ngân hàng Napas...'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn ngân hàng nhận tiền'), findsOneWidget);
      expect(find.text('VCB'), findsOneWidget);

      // Chọn Vietcombank
      await tester.tap(find.text('VCB'));
      await tester.pumpAndSettle();

      // Kiểm tra ngân hàng đã được chọn trên form
      expect(find.textContaining('VCB'), findsOneWidget);
    });

    testWidgets('ProfileBankScreen render hồ sơ người dùng và nút lưu thông tin', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      const testUser = UserModel(
        id: 'u_profile',
        name: 'Hoàng Nam',
        email: 'nam@gmail.com',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileBankScreen(user: testUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hồ sơ & Tài khoản VietQR'), findsOneWidget);
      expect(find.text('Hoàng Nam'), findsWidgets);
      expect(find.text('nam@gmail.com'), findsOneWidget);
      expect(find.text('Lưu thông tin ngân hàng'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);
    });
  });
}
