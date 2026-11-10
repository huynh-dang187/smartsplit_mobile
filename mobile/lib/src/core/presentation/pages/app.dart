import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartsplit_mobile/src/common/configs/app_config.dart';
import 'package:smartsplit_mobile/src/common/constants/app_theme.dart';
import 'package:smartsplit_mobile/src/core/domain/enums/bloc_status.dart';
import 'package:smartsplit_mobile/src/core/presentation/blocs/get_it.dart';
import 'package:smartsplit_mobile/src/core/presentation/cubit/app/app_cubit.dart';
import 'package:smartsplit_mobile/src/core/presentation/widgets/common_loading.dart';

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

        // Tạm thời hiển thị màn hình chào SmartSplit trước khi nối Router các Features
        return Scaffold(
          appBar: AppBar(
            title: const Text('SmartSplit'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: Color(0xFF059669),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chào mừng đến với SmartSplit',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.isAuthenticated
                      ? 'Đăng nhập với tư cách: ${state.currentUser?.name}'
                      : 'Hệ thống cốt lõi (Core & Common) đã sẵn sàng!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
