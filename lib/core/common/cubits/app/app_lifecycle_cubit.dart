import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

@immutable
class AppLifecycleStateVm {
  final AppLifecycleState state;
  const AppLifecycleStateVm(this.state);

  bool get isResumed => state == AppLifecycleState.resumed;
}

/// Holds the app lifecycle in a bloc-friendly way.
///
/// Important architectural boundary:
/// - WidgetsBindingObserver lives in the UI.
/// - Business/session coordinators depend on this cubit instead of widgets.
class AppLifecycleCubit extends Cubit<AppLifecycleStateVm> {
  AppLifecycleCubit() : super(const AppLifecycleStateVm(AppLifecycleState.resumed));

  void setLifecycle(AppLifecycleState s) {
    if (state.state == s) return;
    emit(AppLifecycleStateVm(s));
  }
}
