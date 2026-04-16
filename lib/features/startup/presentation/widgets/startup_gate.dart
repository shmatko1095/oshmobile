import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/features/auth/presentation/pages/signin_page.dart';
import 'package:oshmobile/features/home/presentation/pages/home_page.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';
import 'package:oshmobile/features/startup/presentation/pages/no_internet_page.dart';
import 'package:oshmobile/features/startup/presentation/pages/startup_force_update_page.dart';
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
  bool _isRecommendDialogOpen = false;

  @override
  Widget build(BuildContext context) {
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
            StartupStage.checkingPolicy => StartupLoader(
                message: s.startupCheckingAppVersion,
              ),
            StartupStage.restoringSession => const StartupLoader(),
            StartupStage.noInternet => NoInternetPage(
                onRetry: () => unawaited(context.read<StartupCubit>().retry()),
                isChecking: state.isRetrying,
              ),
            StartupStage.ready => state.hardUpdateRequired
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
    if (_isRecommendDialogOpen || !mounted) {
      return;
    }

    _isRecommendDialogOpen = true;
    try {
      await showStartupRecommendUpdateDialog(
        context: context,
        onUpdateNow: () async {
          Navigator.of(context, rootNavigator: true).pop();
          await _handleUpdateNowTap(source: 'recommend_update');
        },
        onLater: () async {
          Navigator.of(context, rootNavigator: true).pop();
          await context.read<StartupCubit>().onRecommendLaterTapped();
        },
      );
    } finally {
      _isRecommendDialogOpen = false;
      if (mounted) {
        await context.read<StartupCubit>().onRecommendPromptDismissed();
      }
    }
  }

  Future<void> _handleUpdateNowTap({required String source}) async {
    final cubit = context.read<StartupCubit>();
    await cubit.onUpdateNowTapped(source: source);

    final rawUrl = cubit.currentStoreUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      await OshCrashReporter.logNonFatal(
        FormatException('Invalid store URL: $rawUrl'),
        StackTrace.current,
        reason: 'Unable to open app store URL',
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      await OshCrashReporter.logNonFatal(
        StateError('launchUrl returned false: $uri'),
        StackTrace.current,
        reason: 'Unable to open app store URL',
      );
    }
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
