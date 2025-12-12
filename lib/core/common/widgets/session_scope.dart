import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/init_dependencies.dart';

/// Provides session-scoped BLoCs/Cubits.
///
/// A "session" starts when the user becomes authenticated and ends on logout.
/// Everything created here will be disposed automatically when the auth state
/// switches back to unauthenticated (because this widget leaves the tree).
class SessionScope extends StatelessWidget {
  final Widget child;

  const SessionScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // HomeCubit must not outlive the authenticated session.
        BlocProvider<HomeCubit>(
          create: (_) => locator<HomeCubit>(),
        ),
      ],
      child: child,
    );
  }
}
