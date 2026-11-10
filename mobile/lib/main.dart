import 'package:flutter/material.dart';
import 'src/core/presentation/blocs/get_it.dart';
import 'src/core/presentation/pages/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Dependency Injection (SecuredStorage, RestfulRequest, AppCubit)
  await initDependencies();

  runApp(const SmartSplitRootApp());
}
