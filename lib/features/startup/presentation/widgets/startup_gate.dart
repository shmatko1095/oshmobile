import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/home/presentation/pages/home_page.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';
import 'package:oshmobile/features/startup/presentation/pages/no_internet_page.dart';
import 'package:oshmobile/features/startup/presentation/widgets/startup_loader.dart';
import 'package:oshmobile/generated/l10n.dart';

class StartupGate extends StatelessWidget {
  const StartupGate({
    super.key,
    this.authenticatedBuilder,
    this.unauthenticatedBuilder,
  });

  final WidgetBuilder? authenticatedBuilder;
  final WidgetBuilder? unauthenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartupCubit, StartupState>(
      builder: (context, state) {
        final s = S.of(context);

        return switch (state.stage) {
          StartupStage.checkingConnectivity => StartupLoader(
              message: s.startupCheckingInternet,
            ),
          StartupStage.restoringSession => const StartupLoader(),
          StartupStage.noInternet => NoInternetPage(
              onRetry: () => unawaited(context.read<StartupCubit>().retry()),
              isChecking: state.isRetrying,
            ),
          StartupStage.ready => _AuthGate(
              authenticatedBuilder: authenticatedBuilder,
              unauthenticatedBuilder: unauthenticatedBuilder,
            ),
        };
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({
    this.authenticatedBuilder,
    this.unauthenticatedBuilder,
  });

  final WidgetBuilder? authenticatedBuilder;
  final WidgetBuilder? unauthenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlobalAuthCubit, GlobalAuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return authenticatedBuilder?.call(context) ?? const HomePage();
        }

        return unauthenticatedBuilder?.call(context) ?? const SignInPage();
      },
    );
  }
}
