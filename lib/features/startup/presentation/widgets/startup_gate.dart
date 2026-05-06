import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/home/presentation/pages/home_page.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';
import 'package:oshmobile/features/startup/presentation/pages/no_internet_page.dart';
import 'package:oshmobile/features/startup/presentation/pages/startup_force_update_page.dart';
import 'package:oshmobile/features/startup/presentation/widgets/mobile_policy_update_flow.dart';
import 'package:oshmobile/features/startup/presentation/widgets/startup_loader.dart';
import 'package:oshmobile/features/startup/presentation/widgets/startup_recommend_update_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    this.authenticatedBuilder,
    this.unauthenticatedBuilder,
  });

  final WidgetBuilder? authenticatedBuilder;
  final WidgetBuilder? unauthenticatedBuilder;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Route<void>? _recommendDialogRoute;
  Route<void>? _forceUpdateRoute;

  @override
  Widget build(BuildContext context) {
    final shouldUseForceUpdateOverlay = _shouldUseForceUpdateOverlay();

    return MultiBlocListener(
      listeners: [
        BlocListener<AppLifecycleCubit, AppLifecycleStateVm>(
          listenWhen: (previous, current) =>
              previous.state != current.state && current.isResumed,
          listener: (context, _) {
            unawaited(context.read<StartupCubit>().onAppResumed());
          },
        ),
        BlocListener<StartupCubit, StartupState>(
          listenWhen: (previous, current) {
            return previous.hardUpdateRequired != current.hardUpdateRequired ||
                previous.stage != current.stage;
          },
          listener: (context, state) {
            final shouldBlock =
                state.stage == StartupStage.ready && state.hardUpdateRequired;
            if (!shouldBlock || !_shouldUseForceUpdateOverlay()) {
              _dismissForceUpdateGate();
              return;
            }

            unawaited(_presentForceUpdateGate());
          },
        ),
        BlocListener<StartupCubit, StartupState>(
          listenWhen: (previous, current) {
            return previous.recommendPromptRequestId !=
                    current.recommendPromptRequestId &&
                current.pendingRecommendPrompt &&
                current.stage == StartupStage.ready &&
                !current.hardUpdateRequired;
          },
          listener: (context, _) {
            unawaited(_presentRecommendUpdateDialog());
          },
        ),
      ],
      child: BlocBuilder<StartupCubit, StartupState>(
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
            StartupStage.ready => state.hardUpdateRequired &&
                    !shouldUseForceUpdateOverlay
                ? StartupForceUpdatePage(
                    onUpdateNow: () => unawaited(
                      _handleUpdateNowTap(source: 'require_update'),
                    ),
                  )
                : _AuthGate(
                    authenticatedBuilder: widget.authenticatedBuilder,
                    unauthenticatedBuilder: widget.unauthenticatedBuilder,
                  ),
          };
        },
      ),
    );
  }

  Future<void> _presentRecommendUpdateDialog() async {
    final startupState = context.read<StartupCubit>().state;
    if (_recommendDialogRoute != null ||
        _forceUpdateRoute != null ||
        startupState.hardUpdateRequired ||
        !mounted) {
      return;
    }

    final route = createStartupRecommendUpdateRoute(
      context: context,
      onUpdateNow: () {
        unawaited(_handleRecommendUpdateNow());
      },
      onLater: () {
        unawaited(_handleRecommendLater());
      },
    );

    _recommendDialogRoute = route;
    try {
      await Navigator.of(context, rootNavigator: true).push<void>(route);
    } finally {
      if (identical(_recommendDialogRoute, route)) {
        _recommendDialogRoute = null;
      }
      if (mounted) {
        await context.read<StartupCubit>().onRecommendPromptDismissed();
      }
    }
  }

  Future<void> _handleRecommendUpdateNow() async {
    await _dismissRecommendUpdateDialog();
    if (!mounted) {
      return;
    }

    await _handleUpdateNowTap(source: 'recommend_update');
  }

  Future<void> _handleRecommendLater() async {
    await _dismissRecommendUpdateDialog();
    if (!mounted) {
      return;
    }

    await context.read<StartupCubit>().onRecommendLaterTapped();
  }

  Future<void> _presentForceUpdateGate() async {
    if (_forceUpdateRoute != null || !_shouldUseForceUpdateOverlay() || !mounted) {
      return;
    }

    await _dismissRecommendUpdateDialog();
    if (!mounted) {
      return;
    }

    final route = createBlockingStartupForceUpdateRoute(
      onUpdateNow: () => unawaited(
        _handleUpdateNowTap(source: 'require_update'),
      ),
    );

    _forceUpdateRoute = route;
    try {
      await Navigator.of(context, rootNavigator: true).push<void>(route);
    } finally {
      if (identical(_forceUpdateRoute, route)) {
        _forceUpdateRoute = null;
      }
    }
  }

  Future<void> _dismissRecommendUpdateDialog() async {
    final route = _recommendDialogRoute;
    if (route == null) {
      return;
    }

    _recommendDialogRoute = null;
    _removeRoute(route);
    await Future<void>.delayed(Duration.zero);
  }

  void _dismissForceUpdateGate() {
    final route = _forceUpdateRoute;
    if (route == null) {
      return;
    }

    _forceUpdateRoute = null;
    _removeRoute(route);
  }

  void _removeRoute(Route<void> route) {
    if (!route.isActive) {
      return;
    }

    final navigator = route.navigator;
    if (navigator == null) {
      return;
    }

    navigator.removeRoute(route);
  }

  bool _shouldUseForceUpdateOverlay() {
    final route = ModalRoute.of(context);
    return route != null && !route.isCurrent;
  }

  Future<void> _handleUpdateNowTap({required String source}) async {
    final cubit = context.read<StartupCubit>();
    await launchMobilePolicyUpdate(
      source: source,
      storeUrl: cubit.currentStoreUrl,
      status: cubit.state.policyStatus,
      policy: cubit.state.policy,
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
