import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart' as global_auth;
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart' as global_mqtt;
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/widgets/auth_mqtt_coordinator.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/pages/home_page.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';
import 'package:oshmobile/startup_error_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await initDependencies();
  } catch (e, st) {
    debugPrint('initDependencies failed: $e');
    debugPrint(st.toString());
    runApp(StartupErrorApp(error: e.toString()));
    return;
  }

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => locator<global_auth.GlobalAuthCubit>()),
      BlocProvider(create: (_) => locator<global_mqtt.GlobalMqttCubit>()),
      BlocProvider(create: (_) => locator<MqttCommCubit>()),
      BlocProvider(create: (_) => locator<AuthBloc>()),
      BlocProvider(create: (_) => locator<HomeCubit>()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    context.read<global_auth.GlobalAuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return AuthMqttCoordinator(
        child: MaterialApp(
      title: 'OSH Mobile',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: BlocBuilder<global_auth.GlobalAuthCubit, global_auth.GlobalAuthState>(
        builder: (_, state) => (state is global_auth.AuthAuthenticated) ? const HomePage() : const SignInPage(),
      ),
    ));
  }
}
