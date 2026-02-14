import 'package:get_it/get_it.dart';
import '../../features/calls/data/repositories/call_repository_impl.dart';
import '../../features/calls/domain/repositories/call_repository.dart';
import '../../features/calls/presentation/cubit/call_cubit.dart';
import '../../features/calls/data/datasources/call_interceptor_service.dart';
import '../database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Database
  sl.registerLazySingleton(() => AppDatabase());

  // Repository
  sl.registerLazySingleton<CallRepository>(
    () => CallRepositoryImpl(sl()),
  );

  // Service
  sl.registerLazySingleton(() => CallInterceptorService(sl()));

  // Cubit
  sl.registerFactory(() => CallCubit(sl()));
  // Settings Feature
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );
  sl.registerFactory(() => SettingsCubit(sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
