import 'package:flutter/material.dart';

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

  /// Hàm điều hướng chung (sẽ hoàn thiện khi phát triển từng Feature)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}
