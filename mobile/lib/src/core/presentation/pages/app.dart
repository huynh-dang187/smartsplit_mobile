import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/common/configs/app_config.dart';
import 'package:smartsplit_mobile/src/common/constants/app_theme.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/cubit/app/app_cubit.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_loading.dart';
import 'package:smartsplit_mobile/src/features/auth/presentation/pages/login_screen.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/pages/group_list_screen.dart';
import 'package:smartsplit_mobile/src/shared/router/app_router.dart';

/// Root Widget khởi chạy MaterialApp cho ứng dụng SmartSplit.
class SmartSplitRootApp extends StatelessWidget {
  const SmartSplitRootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AppCubit>()..checkAuthSession(),
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const _AppSessionGate(),
      ),
    );
  }
}

/// Cổng kiểm tra phiên đăng nhập người dùng khi mở ứng dụng
class _AppSessionGate extends StatelessWidget {
  const _AppSessionGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.status.isLoading) {
          return const Scaffold(
            body: Center(
              child: CommonShimmer(width: 120, height: 28),
            ),
          );
        }

        // Nếu chưa đăng nhập: chuyển tới LoginScreen
        if (!state.isAuthenticated) {
          return const LoginScreen();
        }

        // Khi đã đăng nhập: hiển thị màn hình danh sách nhóm chính
        return const GroupListScreen();
      },
    );
  }
}
