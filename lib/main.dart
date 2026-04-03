import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/common/widgets/app_lifecycle_observer.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart'
    as global_auth;
import 'package:oshmobile/app/session/scopes/session_scope.dart';
import 'package:oshmobile/core/logging/osh_bloc_observer.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/home/presentation/pages/home_page.dart';
import 'package:oshmobile/features/startup/presentation/pages/no_internet_page.dart';
import 'package:oshmobile/firebase_options.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';
import 'package:oshmobile/startup_error_app.dart';

bool _isBackgroundSocketAbort(Object error) {
  if (error is! SocketException) return false;

  final code = error.osError?.errorCode;
  // 103: Software caused connection abort (Linux/Android)
  // 104: Connection reset by peer (Linux)
  // 54:  Connection reset by peer (Darwin/iOS)
  return code == 103 || code == 104 || code == 54;
}

void _reportUncaughtError(
  Object error,
  StackTrace stack, {
  required String reason,
}) {
  // Mobile OS may abort sockets when app goes to background.
  // Treat common "connection aborted" errors as non-fatal to avoid noisy crash reports.
  if (_isBackgroundSocketAbort(error)) {
    unawaited(
      OshCrashReporter.logNonFatal(
        error,
        stack,
        reason: 'Socket aborted by OS (background)',
      ),
    );
    return;
  }

  unawaited(
    OshCrashReporter.logFatal(
      error,
      stack,
      reason: reason,
    ),
  );
}

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await OshCrashReporter.setCollectionEnabled(kReleaseMode);
    Bloc.observer = OshBlocObserver();

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _reportUncaughtError(
        error,
        stack,
        reason: 'Uncaught platform dispatcher error',
      );
      return true;
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
          BlocProvider(create: (_) => locator<AppLifecycleCubit>()),
          BlocProvider(create: (_) => locator<AppThemeCubit>()),
          BlocProvider(create: (_) => locator<global_auth.GlobalAuthCubit>()),
          BlocProvider(create: (_) => locator<AuthBloc>()),
        ],
        child: AppLifecycleObserver(child: const MyApp()),
      ),
    );
  }, (Object error, StackTrace stack) {
    _reportUncaughtError(
      error,
      stack,
      reason: 'Uncaught zone error',
    );
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
  bool _internetCheckResolved = false;
  bool _hasInternetAtStartup = false;
  bool _isRetryingInternetCheck = false;
  bool _authBootstrapStarted = false;

  @override
  void initState() {
    super.initState();
    _checkInternetBeforeStartup();
  }

  void _handleAuthTransition(global_auth.GlobalAuthState next) {
    final auth = context.read<global_auth.GlobalAuthCubit>();

    if (next is global_auth.AuthAuthenticated) {
      final userKey = auth.getJwtUserData()?.uuid;
      final shouldStartNewSession =
          !_inSession || (userKey != null && userKey != _sessionUserKey);
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

  Future<void> _checkInternetBeforeStartup({bool fromRetry = false}) async {
    if (fromRetry) {
      if (!mounted) return;
      setState(() {
        _isRetryingInternetCheck = true;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _internetCheckResolved = false;
        _isRetryingInternetCheck = false;
      });
    }

    bool isConnected = false;
    try {
      isConnected = await locator<InternetConnectionChecker>().isConnected;
    } catch (e, st) {
      OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'Startup internet check failed',
      );
    }

    if (!mounted) return;

    if (isConnected && !_authBootstrapStarted) {
      _authBootstrapStarted = true;
      context.read<global_auth.GlobalAuthCubit>().checkAuthStatus();
    }

    setState(() {
      _internetCheckResolved = true;
      _hasInternetAtStartup = isConnected;
      _isRetryingInternetCheck = false;
    });
  }

  Widget _buildStartupHome() {
    if (!_internetCheckResolved) {
      return const _StartupBootstrapLoader();
    }

    if (!_hasInternetAtStartup) {
      return NoInternetPage(
        onRetry: () => _checkInternetBeforeStartup(fromRetry: true),
        isChecking: _isRetryingInternetCheck,
      );
    }

    return BlocBuilder<global_auth.GlobalAuthCubit,
        global_auth.GlobalAuthState>(
      builder: (_, state) => (state is global_auth.AuthAuthenticated)
          ? const HomePage()
          : const SignInPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocListener<global_auth.GlobalAuthCubit,
            global_auth.GlobalAuthState>(
          listener: (context, state) => _handleAuthTransition(state),
          child: MaterialApp(
            key: ValueKey('nav_$_sessionEpoch'),
            title: 'Oshhome',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
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
              if (userId == null ||
                  token == null ||
                  userId.isEmpty ||
                  token.isEmpty) {
                return nav;
              }

              return SessionScope(
                key: ValueKey('session_$_sessionEpoch'),
                userId: userId,
                token: token,
                child: nav,
              );
            },
            home: _buildStartupHome(),
          ),
        );
      },
    );
  }
}

class _StartupBootstrapLoader extends StatelessWidget {
  const _StartupBootstrapLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.canvas,
      body: const SafeArea(
        child: Center(
          child: _StartupBootstrapLoaderBody(),
        ),
      ),
    );
  }
}

class _StartupBootstrapLoaderBody extends StatelessWidget {
  const _StartupBootstrapLoaderBody();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppPalette.spaceLg),
        Text(
          s.startupCheckingInternet,
          style: const TextStyle(color: AppPalette.textSecondary),
        ),
      ],
    );
  }
}
