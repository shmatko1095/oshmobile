import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/presentation/pages/startup_force_update_page.dart';

Route<void> createBlockingStartupForceUpdateRoute({
  required VoidCallback onUpdateNow,
}) {
  return PageRouteBuilder<void>(
    settings: const RouteSettings(name: 'startup_force_update'),
    transitionDuration: AppPalette.motionSlow,
    reverseTransitionDuration: AppPalette.motionSlow,
    pageBuilder: (_, __, ___) {
      return PopScope(
        canPop: false,
        child: StartupForceUpdatePage(onUpdateNow: onUpdateNow),
      );
    },
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}

Future<void> launchMobilePolicyUpdate({
  required String source,
  required String? storeUrl,
  MobileClientPolicyStatus? status,
  MobileClientPolicy? policy,
}) async {
  await OshAnalytics.logEvent(
    OshAnalyticsEvents.mobilePolicyUpdateTapped,
    parameters: {
      'source': source,
      'status': status?.wireValue,
      'policy_version': policy?.policyVersion,
    },
  );

  final rawUrl = storeUrl?.trim() ?? '';
  if (rawUrl.isEmpty) {
    return;
  }

  final uri = Uri.tryParse(rawUrl);
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

Future<void> showBlockingStartupForceUpdateFlow({
  required BuildContext context,
  required VoidCallback onUpdateNow,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    createBlockingStartupForceUpdateRoute(
      onUpdateNow: onUpdateNow,
    ),
  );
}
