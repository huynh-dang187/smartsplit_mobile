import 'package:get_it/get_it.dart';
import 'package:smartsplit_mobile/src/features/auth/domain/interfaces/i_auth_repositories.dart';
import 'package:smartsplit_mobile/src/features/auth/infrastructure/repositories/auth_repositories.dart';
import 'package:smartsplit_mobile/src/features/expenses/domain/interfaces/i_expense_repositories.dart';
import 'package:smartsplit_mobile/src/features/expenses/infrastructure/repositories/expense_repositories.dart';
import 'package:smartsplit_mobile/src/features/groups/domain/interfaces/i_group_repositories.dart';
import 'package:smartsplit_mobile/src/features/groups/infrastructure/repositories/group_repositories.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_detail_cubit.dart';
import 'package:smartsplit_mobile/src/features/groups/presentation/cubits/group_list_cubit.dart';
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

  // 4. Feature Repositories (Lazy Singleton)
  getIt.registerLazySingleton<IAuthRepositories>(
    () => AuthRepositories(
      restfulRequest: getIt<RestfulRequest>(),
      securedStorage: getIt<SecuredStorage>(),
    ),
  );

  getIt.registerLazySingleton<IGroupRepositories>(
    () => GroupRepositories(
      restfulRequest: getIt<RestfulRequest>(),
    ),
  );

  getIt.registerLazySingleton<IExpenseRepositories>(
    () => ExpenseRepositories(
      restfulRequest: getIt<RestfulRequest>(),
    ),
  );

  // 5. Feature Cubits (Factory)
  getIt.registerFactory<GroupListCubit>(
    () => GroupListCubit(groupRepositories: getIt<IGroupRepositories>()),
  );

  getIt.registerFactory<GroupDetailCubit>(
    () => GroupDetailCubit(groupRepositories: getIt<IGroupRepositories>()),
  );
}
