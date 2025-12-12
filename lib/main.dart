import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart' as global_auth;
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart' as global_mqtt;
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/widgets/auth_mqtt_coordinator.dart';
import 'package:oshmobile/core/logging/osh_bloc_observer.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/pages/home_page.dart';
import 'package:oshmobile/firebase_options.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';
import 'package:oshmobile/startup_error_app.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // await OshCrashReporter.setCollectionEnabled(!kDebugMode);
    await OshCrashReporter.setCollectionEnabled(true);
    Bloc.observer = OshBlocObserver();

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

      try {
        await initDependencies();
      } catch (e, st) {
        OshCrashReporter.logNonFatal(e, st, reason: 'initDependencies failed');
        debugPrint('initDependencies failed: $e');
        debugPrint(st.toString());
        runApp(StartupErrorApp(error: e.toString()));
        return;
      }

      runApp(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => locator<global_auth.GlobalAuthCubit>()),
            BlocProvider(create: (_) => locator<global_mqtt.GlobalMqttCubit>()),
            BlocProvider(create: (_) => locator<MqttCommCubit>()),
            BlocProvider(create: (_) => locator<AuthBloc>()),
            BlocProvider(create: (_) => locator<HomeCubit>()),
          ],
          child: const MyApp(),
        ),
      );
    }, (Object error, StackTrace stack) {
      OshCrashReporter.logFatal(error, stack, reason: 'Uncaught zone error');
    },
  );
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
      theme: AppTheme.darkTheme,
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
