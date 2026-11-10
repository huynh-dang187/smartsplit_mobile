import 'package:get_it/get_it.dart';
import '../../infrastructure/datasources/local/secured_storage.dart';
import '../../infrastructure/datasources/network/api/restful_request.dart';
import '../cubit/app/app_cubit.dart';

final GetIt getIt = GetIt.instance;

/// Khởi tạo và đăng ký toàn bộ Service, DataSource, Repository và Core Cubit.
Future<void> initDependencies() async {
  // 1. Local Storage
  final securedStorage = await SecuredStorage.init();
  getIt.registerSingleton<SecuredStorage>(securedStorage);

  // 2. Network Client
  final restfulRequest = RestfulRequest(securedStorage: securedStorage);
  getIt.registerSingleton<RestfulRequest>(restfulRequest);

  // 3. Core Cubit (Toàn cục)
  getIt.registerLazySingleton<AppCubit>(
    () => AppCubit(securedStorage: getIt<SecuredStorage>()),
  );
}
