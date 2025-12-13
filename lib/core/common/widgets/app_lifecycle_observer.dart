import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';

/// A tiny UI-only adapter that reports app lifecycle to [AppLifecycleCubit].
///
/// It does NOT know anything about MQTT/auth/session.
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Report to cubit (no async, no business logic here).
    context.read<AppLifecycleCubit>().setLifecycle(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
