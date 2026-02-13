import 'package:get_it/get_it.dart';
import '../../features/calls/data/repositories/call_repository_impl.dart';
import '../../features/calls/domain/repositories/call_repository.dart';
import '../../features/calls/presentation/cubit/call_cubit.dart';
import '../../features/calls/data/datasources/call_interceptor_service.dart';
import '../database/app_database.dart';

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
}
