import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/features/user_guide/presentation/show_user_guide_modal.dart';
import 'package:oshmobile/features/user_guide/presentation/widgets/user_guide_modal.dart';
import 'package:oshmobile/generated/l10n.dart';

import '../../test_user_guide_progress_repository.dart';

void main() {
  testWidgets('manual modal has no Done button and closes through X',
      (tester) async {
    final cubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpLauncher(tester, cubit: cubit);

    await tester.tap(find.byKey(const ValueKey('open-user-guide')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(UserGuideModal), findsOneWidget);
    expect(find.byKey(const ValueKey('user-guide-pages')), findsOneWidget);
    expect(find.text('User guide'), findsOneWidget);
    expect(find.text('Swipe up to view live values'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-preview')),
      findsOneWidget,
    );
    expect(cubit.state.isManualSessionActive, isTrue);

    expect(
      find.byKey(const ValueKey('user-guide-next-or-done')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('user-guide-next')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('user-guide-close')));
    await tester.pumpAndSettle();

    expect(find.byType(UserGuideModal), findsNothing);
    expect(cubit.state.isManualSessionActive, isFalse);
    expect(cubit.state.completedTopics, isEmpty);
  });

  testWidgets('manual guide honors reduced motion', (tester) async {
    final cubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpLauncher(
      tester,
      cubit: cubit,
      disableAnimations: true,
    );

    await tester.tap(find.byKey(const ValueKey('open-user-guide')));
    await tester.pump();

    expect(find.byType(UserGuideModal), findsOneWidget);
  });

  testWidgets('manual guide remains usable on compact screens with large text',
      (tester) async {
    final cubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpLauncher(
      tester,
      cubit: cubit,
      size: const Size(320, 568),
      textScale: 2,
    );

    await tester.tap(find.byKey(const ValueKey('open-user-guide')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('user-guide-close')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-guide-next-or-done')),
      findsNothing,
    );
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required UserGuideCubit cubit,
  bool disableAnimations = false,
  Size size = const Size(400, 800),
  double textScale = 1,
}) {
  return tester.pumpWidget(
    BlocProvider<UserGuideCubit>.value(
      value: cubit,
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    key: const ValueKey('open-user-guide'),
                    onPressed: () => showUserGuideModal(context),
                    child: const Text('Open guide'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
