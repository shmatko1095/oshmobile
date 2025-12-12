import 'package:flutter_bloc/flutter_bloc.dart';

import 'osh_crash_reporter.dart';

/// Global BlocObserver that reports Bloc/Cubit errors to Crashlytics.
class OshBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // Send non-fatal error to Crashlytics with some context.
    OshCrashReporter.logNonFatal(
      error,
      stackTrace,
      reason: 'Bloc error in ${bloc.runtimeType}',
      context: {
        'bloc': bloc.runtimeType.toString(),
      },
    );

    super.onError(bloc, error, stackTrace);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    // OshCrashReporter.log(
    //   'Bloc event: ${bloc.runtimeType}, event: $event',
    // );

    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    // OshCrashReporter.log(
    //   'Bloc change: ${bloc.runtimeType}, change: $change',
    // );
    super.onChange(bloc, change);
  }
}
