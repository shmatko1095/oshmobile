import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_live_metrics_overlay.dart';
import 'package:oshmobile/features/devices/details/presentation/user_guide/thermostat_live_metrics_guide_gate.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

import '../../../../user_guide/test_user_guide_progress_repository.dart';

void main() {
  testWidgets(
      'real live sheet follows the guide gesture and keeps automatic guide active',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(tester, cubit: cubit);

    final coach = find.byKey(
      const ValueKey('user-guide-live-metrics-coach'),
    );
    final gesture = await tester.startGesture(tester.getCenter(coach));
    await gesture.moveBy(const Offset(0, -32));
    await tester.pump();

    expect(_sheetSize(tester), greaterThan(0));
    expect(_sheetSize(tester), lessThan(1));
    expect(cubit.state.completedTopics, isEmpty);

    await gesture.moveBy(const Offset(0, -40));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 40));

    expect(_sheetSize(tester), lessThan(1));
    expect(cubit.state.completedTopics, isEmpty);

    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(1, 0.001));
    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isFalse,
    );
  });

  testWidgets('weak and horizontal gestures do not dismiss or open the guide',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(tester, cubit: cubit);

    final coach = find.byKey(
      const ValueKey('user-guide-live-metrics-coach'),
    );
    expect(coach, findsOneWidget);

    await tester.timedDrag(
      coach,
      const Offset(0, -30),
      const Duration(milliseconds: 500),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(coach, findsOneWidget);
    expect(_sheetSize(tester), closeTo(0, 0.001));

    await tester.drag(coach, const Offset(-120, 0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(coach, findsOneWidget);
    expect(_sheetSize(tester), closeTo(0, 0.001));
    expect(cubit.state.completedTopics, isEmpty);

    final diagonalGesture = await tester.startGesture(tester.getCenter(coach));
    await diagonalGesture.moveBy(const Offset(-48, -36));
    await tester.pump();
    expect(_sheetSize(tester), closeTo(0, 0.001));
    await diagonalGesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('threshold haptic fires only once during one guide gesture',
      (tester) async {
    final hapticCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') hapticCalls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(tester, cubit: cubit);

    final coach = find.byKey(
      const ValueKey('user-guide-live-metrics-coach'),
    );
    final gesture = await tester.startGesture(tester.getCenter(coach));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 12));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -16));
    await tester.pump();

    expect(hapticCalls, hasLength(1));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'successful upward automatic gesture opens sheet without finishing guide',
      (tester) async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpCoach(tester, cubit: cubit);

    await tester.timedDrag(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      const Offset(0, -72),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isFalse,
    );
    expect(repository.saveCount, 0);
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );
    expect(_sheetSize(tester), closeTo(1, 0.001));
  });

  testWidgets('automatic guide returns after live sheet is swiped down',
      (tester) async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();
    await _pumpCoach(tester, cubit: cubit);

    await tester.timedDrag(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      const Offset(0, -72),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(1, 0.001));

    await tester.drag(find.text('Live content'), const Offset(0, 520));
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(0, 0.001));
    expect(cubit.state.completedTopics, isEmpty);
    expect(repository.saveCount, 0);
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('user-guide-skip')),
      findsOneWidget,
    );
  });

  testWidgets(
      'manual session returns after live sheet is closed with system back',
      (tester) async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.startManualGuide();
    await _pumpCoach(tester, cubit: cubit);

    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );

    await tester.timedDrag(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      const Offset(0, -72),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(1, 0.001));
    expect(cubit.state.isManualSessionActive, isTrue);
    expect(cubit.state.completedTopics, isEmpty);
    expect(repository.saveCount, 0);
    expect(cubit.state.sessionPageIndex, 0);
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(0, 0.001));
    expect(cubit.state.isManualSessionActive, isTrue);
    expect(cubit.state.sessionPageIndex, 0);
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('user-guide-skip')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('user-guide-skip')));
    await tester.pumpAndSettle();

    expect(cubit.state.isManualSessionActive, isFalse);
    expect(
      cubit.state.sessionSuppressedTopics,
      contains(UserGuideTopic.thermostatLiveMetricsV1),
    );
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsNothing,
    );
  });

  testWidgets('manual session returns after live sheet is swiped down',
      (tester) async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.startManualGuide();
    await _pumpCoach(tester, cubit: cubit);

    await tester.timedDrag(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      const Offset(0, -72),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(1, 0.001));

    await tester.drag(find.text('Live content'), const Offset(0, 520));
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(0, 0.001));
    expect(cubit.state.isManualSessionActive, isTrue);
    expect(cubit.state.sessionPageIndex, 0);
    expect(cubit.state.completedTopics, isEmpty);
    expect(repository.saveCount, 0);
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );
  });

  testWidgets('manual skip returns to dashboard without persisting completion',
      (tester) async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.startManualGuide();
    await _pumpCoach(tester, cubit: cubit);

    await tester.tap(find.byKey(const ValueKey('user-guide-skip')));
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(0, 0.001));
    expect(cubit.state.isManualSessionActive, isFalse);
    expect(cubit.state.completedTopics, isEmpty);
    expect(repository.saveCount, 0);
  });

  testWidgets('manual guide exposes mode and temperature as separate steps',
      (tester) async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.startManualGuide();
    var modeLongPresses = 0;
    var modeActions = 0;
    var temperatureTaps = 0;
    var temperatureActions = 0;

    await _pumpCoach(
      tester,
      cubit: cubit,
      includeManualTargets: true,
      onModeLongPress: () => modeLongPresses++,
      onModeAction: () => modeActions++,
      onTemperatureTap: () => temperatureTaps++,
      onTemperatureAction: () => temperatureActions++,
    );

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('user-guide-next')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('user-guide-next')));
    await tester.pumpAndSettle();

    expect(find.text('Configure an operating mode'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.longPress(find.byKey(const ValueKey('test-mode-target')));
    expect(modeLongPresses, 1);
    await tester.tap(find.byKey(const ValueKey('user-guide-target-action')));
    expect(modeActions, 1);

    await tester.tap(find.byKey(const ValueKey('user-guide-next')));
    await tester.pumpAndSettle();

    expect(find.text('Quick settings'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('user-guide-next')), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('test-temperature-target')),
    );
    expect(temperatureTaps, 1);
    await tester.tap(find.byKey(const ValueKey('user-guide-target-action')));
    expect(temperatureActions, 1);

    await tester.tap(find.byKey(const ValueKey('user-guide-previous')));
    await tester.pumpAndSettle();
    expect(find.text('Configure an operating mode'), findsOneWidget);
    expect(cubit.state.sessionPageIndex, 1);
    expect(cubit.state.isManualSessionActive, isTrue);
    expect(repository.saveCount, 0);
  });

  testWidgets('target steps restore the dashboard if live values are open',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    cubit.startManualGuide();
    await _pumpCoach(
      tester,
      cubit: cubit,
      includeManualTargets: true,
    );

    await tester.timedDrag(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      const Offset(0, -72),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(1, 0.001));

    cubit.selectPage(1);
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(0, 0.001));
    expect(find.text('Configure an operating mode'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('automatic guide exposes the same contextual pages as manual',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(
      tester,
      cubit: cubit,
      includeManualTargets: true,
    );

    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('user-guide-next')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('user-guide-next')));
    await tester.pumpAndSettle();
    expect(find.text('Configure an operating mode'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('user-guide-next')));
    await tester.pumpAndSettle();
    expect(find.text('Quick settings'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(cubit.state.isAutomaticSessionActive, isTrue);
  });

  testWidgets('target steps fit compact screens at 200 percent text scale',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    cubit.startManualGuide();
    cubit.selectPage(1);
    await _pumpCoach(
      tester,
      cubit: cubit,
      includeManualTargets: true,
      size: const Size(320, 568),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(find.text('Configure an operating mode'), findsOneWidget);
    expect(tester.takeException(), isNull);

    cubit.selectPage(2);
    await tester.pumpAndSettle();

    expect(find.text('Quick settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning from a target action preserves the guide step',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    cubit.startManualGuide();
    cubit.selectPage(1);
    final navigatorKey = GlobalKey<NavigatorState>();
    await _pumpCoach(
      tester,
      cubit: cubit,
      includeManualTargets: true,
      navigatorKey: navigatorKey,
      onModeAction: () {
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Mode editor')),
          ),
        );
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('user-guide-target-action')));
    await tester.pumpAndSettle();
    expect(find.text('Mode editor'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Configure an operating mode'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(cubit.state.sessionPageIndex, 1);
    expect(cubit.state.isManualSessionActive, isTrue);
  });

  testWidgets('returning after interacting with the real target preserves it',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    cubit.startManualGuide();
    cubit.selectPage(2);
    final navigatorKey = GlobalKey<NavigatorState>();
    await _pumpCoach(
      tester,
      cubit: cubit,
      includeManualTargets: true,
      navigatorKey: navigatorKey,
      onTemperatureTap: () {
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Temperature editor')),
          ),
        );
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('test-temperature-target')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Temperature editor'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Quick settings'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(cubit.state.sessionPageIndex, 2);
    expect(cubit.state.isManualSessionActive, isTrue);
  });

  testWidgets('skip completes guide without opening live values',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(tester, cubit: cubit);

    await tester.tap(find.byKey(const ValueKey('user-guide-skip')));
    await tester.pumpAndSettle();

    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isTrue,
    );
    expect(_sheetSize(tester), closeTo(0, 0.001));
  });

  testWidgets('semantic tap opens live values without a drag', (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(tester, cubit: cubit);

    final semantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('user-guide-live-metrics-semantics')),
    );
    semantics.properties.onTap!();
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(1, 0.001));
    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isFalse,
    );
  });

  testWidgets('reduced motion keeps direct drag and settles immediately',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(
      tester,
      cubit: cubit,
      disableAnimations: true,
    );

    final coach = find.byKey(
      const ValueKey('user-guide-live-metrics-coach'),
    );
    final gesture = await tester.startGesture(tester.getCenter(coach));
    await gesture.moveBy(const Offset(0, -72));
    await tester.pump();
    expect(_sheetSize(tester), inExclusiveRange(0, 1));

    await gesture.up();
    await tester.pump();
    expect(_sheetSize(tester), closeTo(1, 0.001));
  });

  testWidgets('coach remains usable in light theme at 200 percent text scale',
      (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(
      tester,
      cubit: cubit,
      brightness: Brightness.light,
      textScale: 2,
      size: const Size(320, 568),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('user-guide-skip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-sheet-edge')),
      findsOneWidget,
    );
  });

  testWidgets('system back behaves like skip', (tester) async {
    final cubit = await _createCubit();
    addTearDown(cubit.close);
    await _pumpCoach(tester, cubit: cubit);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isTrue,
    );
    expect(_sheetSize(tester), closeTo(0, 0.001));
  });

  testWidgets('completed guide stays hidden after progress is reloaded',
      (tester) async {
    final cubit = await _createCubit(
      completed: <UserGuideTopic>{
        UserGuideTopic.thermostatLiveMetricsV1,
      },
    );
    addTearDown(cubit.close);
    await _pumpCoach(tester, cubit: cubit);

    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsNothing,
    );
    expect(_sheetSize(tester), closeTo(0, 0.001));
  });
}

Future<UserGuideCubit> _createCubit({Set<UserGuideTopic>? completed}) async {
  final cubit = UserGuideCubit(
    repository: TestUserGuideProgressRepository(
      completedTopics: completed,
    ),
  );
  await cubit.load();
  return cubit;
}

Future<void> _pumpCoach(
  WidgetTester tester, {
  required UserGuideCubit cubit,
  bool disableAnimations = false,
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  Size size = const Size(400, 800),
  bool includeManualTargets = false,
  VoidCallback? onModeLongPress,
  VoidCallback? onModeAction,
  VoidCallback? onTemperatureTap,
  VoidCallback? onTemperatureAction,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  final modeTargetKey = GlobalKey();
  final temperatureTargetKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      theme: ThemeData(
        brightness: brightness,
        scaffoldBackgroundColor:
            brightness == Brightness.dark ? Colors.black : Colors.white,
      ),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: ThermostatLiveMetricsOverlay(
            dashboard: Stack(
              children: [
                const Positioned.fill(
                  child: CustomScrollView(
                    key: ValueKey('guide-test-dashboard'),
                    physics: AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                if (includeManualTargets) ...[
                  Positioned(
                    left: 32,
                    right: 32,
                    top: 110,
                    height: 210,
                    child: KeyedSubtree(
                      key: temperatureTargetKey,
                      child: GestureDetector(
                        key: const ValueKey('test-temperature-target'),
                        behavior: HitTestBehavior.opaque,
                        onTap: onTemperatureTap,
                        child: const ColoredBox(color: Colors.orange),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 36,
                    height: 90,
                    child: KeyedSubtree(
                      key: modeTargetKey,
                      child: GestureDetector(
                        key: const ValueKey('test-mode-target'),
                        behavior: HitTestBehavior.opaque,
                        onLongPress: onModeLongPress,
                        child: const ColoredBox(color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            contentBuilder: (
              context,
              scrollController,
              close,
              titleFocusNode,
            ) {
              return Material(
                color: Colors.black,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: const <Widget>[
                    SliverFillRemaining(child: Text('Live content')),
                  ],
                ),
              );
            },
            foregroundBuilder: (context, interactionController) {
              return ThermostatLiveMetricsGuideGate(
                cubit: cubit,
                interactionController: interactionController,
                modeBarTargetKey: includeManualTargets ? modeTargetKey : null,
                temperatureTargetKey:
                    includeManualTargets ? temperatureTargetKey : null,
                onOpenModeSettings:
                    includeManualTargets ? onModeAction ?? () {} : null,
                onOpenTemperatureSettings:
                    includeManualTargets ? onTemperatureAction ?? () {} : null,
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _sheetSize(WidgetTester tester) {
  final sheet = tester.widget<DraggableScrollableSheet>(
    find.byKey(const ValueKey('thermostat-live-metrics-draggable-sheet')),
  );
  return sheet.controller!.size;
}
