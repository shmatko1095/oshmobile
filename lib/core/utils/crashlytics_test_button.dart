import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';

class CrashlyticsTestButton extends StatelessWidget {
  const CrashlyticsTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Simulate some failing logic.
          throw StateError('Test non-fatal error from CrashlyticsTestButton');
        } catch (e, st) {
          await OshCrashReporter.logNonFatal(
            e,
            st,
            reason: 'User pressed CrashlyticsTestButton',
            context: {
              'screen': 'DebugPage',
              'button': 'CrashlyticsTestButton',
              'build_type': kDebugMode ? 'debug' : 'release',
            },
          );
          SnackBarUtils.showAlert(context: context, content: "Test error sent to Crashlytic");
        }
      },
      child: const Text('Send test error to Crashlytics'),
    );
  }
}
