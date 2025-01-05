import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart'
    as global;
import 'package:oshmobile/core/theme/theme.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/pages/home_page.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => locator<global.GlobalAuthCubit>(),
      ),
      BlocProvider(
        create: (_) => locator<AuthBloc>(),
      ),
      BlocProvider(
        create: (_) => locator<HomeCubit>(),
      ),
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
    context.read<global.GlobalAuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: BlocSelector<global.GlobalAuthCubit, global.GlobalAuthState, bool>(
        selector: (state) => state is global.AuthAuthenticated,
        builder: (_, state) => state ? const HomePage() : const SignInPage(),
      ),
    );
  }
}
