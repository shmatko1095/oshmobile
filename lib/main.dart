import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart' as global_auth;
import 'package:oshmobile/core/scopes/session_scope.dart';
import 'package:oshmobile/core/logging/osh_bloc_observer.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
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
          BlocProvider(create: (_) => locator<AuthBloc>()),
        ],
        child: const MyApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    OshCrashReporter.logFatal(error, stack, reason: 'Uncaught zone error');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Changes only when a *login session* starts/ends or the user identity changes.
  int _sessionEpoch = 0;

  bool _inSession = false;
  String? _sessionUserKey;

  @override
  void initState() {
    super.initState();
    context.read<global_auth.GlobalAuthCubit>().checkAuthStatus();
  }

  void _handleAuthTransition(global_auth.GlobalAuthState next) {
    final auth = context.read<global_auth.GlobalAuthCubit>();

    if (next is global_auth.AuthAuthenticated) {
      final userKey = auth.getJwtUserData()?.uuid;
      final shouldStartNewSession = !_inSession || (userKey != null && userKey != _sessionUserKey);
      if (shouldStartNewSession) {
        setState(() {
          _inSession = true;
          _sessionUserKey = userKey;
          _sessionEpoch++;
        });
      }
      return;
    }

    if (_inSession) {
      setState(() {
        _inSession = false;
        _sessionUserKey = null;
        _sessionEpoch++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<global_auth.GlobalAuthCubit, global_auth.GlobalAuthState>(
      listener: (context, state) => _handleAuthTransition(state),
      child: MaterialApp(
        key: ValueKey('nav_$_sessionEpoch'),
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
        builder: (context, child) {
          final nav = child ?? const SizedBox.shrink();

          final authCubit = context.read<global_auth.GlobalAuthCubit>();
          final isAuthed = authCubit.state is global_auth.AuthAuthenticated;
          if (!isAuthed) return nav;

          final userId = authCubit.getJwtUserData()?.uuid;
          final token = authCubit.getAccessToken();
          if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
            return nav;
          }

          return SessionScope(
            key: ValueKey('session_$_sessionEpoch'),
            userId: userId,
            token: token,
            child: nav,
          );
        },
        home: BlocBuilder<global_auth.GlobalAuthCubit, global_auth.GlobalAuthState>(
          builder: (_, state) => (state is global_auth.AuthAuthenticated) ? const HomePage() : const SignInPage(),
        ),
      ),
    );
  }
}
