import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/profile_bank_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/groups/presentation/pages/group_detail_screen.dart';
import '../../features/groups/presentation/pages/group_list_screen.dart';

/// Định nghĩa các Route Name và điều hướng màn hình cho toàn bộ ứng dụng SmartSplit.
abstract class AppRouter {
  // --- AUTH ROUTES ---
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profileBank = '/profile-bank';

  // --- GROUP ROUTES ---
  static const String groupList = '/groups';
  static const String groupDetail = '/group-detail';
  static const String createGroup = '/create-group';
  static const String addMember = '/add-member';

  // --- EXPENSE & SPLIT WORKSPACE ROUTES ---
  static const String splitWorkspace = '/split-workspace';
  static const String expenseDetail = '/expense-detail';

  /// Điều hướng màn hình tập trung
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case profileBank:
        return MaterialPageRoute(builder: (_) => const ProfileBankScreen());
      case groupList:
        return MaterialPageRoute(builder: (_) => const GroupListScreen());
      case groupDetail:
        final args = settings.arguments;
        final groupId = args is String
            ? args
            : (args is Map ? args['groupId']?.toString() ?? '' : '');
        return MaterialPageRoute(
          builder: (_) => GroupDetailScreen(groupId: groupId),
        );
      default:
        return null;
    }
  }
}
