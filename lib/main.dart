import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_router.dart';
import 'features/calls/data/datasources/call_interceptor_service.dart';
import 'features/calls/presentation/cubit/call_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  di.sl<CallInterceptorService>().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<CallCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Bina Intercept',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
