import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_live_metrics_overlay.dart';

void main() {
  testWidgets('opens only after a deliberate upward dashboard drag',
      (tester) async {
    await _pumpOverlay(tester);

    final dashboard = find.byKey(
      const ValueKey('test-live-metrics-dashboard-scroll'),
    );
    expect(
      find.byKey(const ValueKey('thermostat-live-metrics-handle')),
      findsNothing,
    );

    await tester.timedDrag(
      dashboard,
      const Offset(0, -30),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(0, 0.001));

    await tester.drag(dashboard, const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(0, 0.001));

    await tester.timedDrag(
      dashboard,
      const Offset(0, -72),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(1, 0.001));
  });

  testWidgets('system back, close button and down swipe control sheet',
      (tester) async {
    await _pumpOverlay(tester);

    await _openWithSwipe(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(0, 0.001));

    await _openWithSwipe(tester);
    await tester.tap(find.byKey(const ValueKey('test-live-metrics-close')));
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(0, 0.001));

    await _openWithSwipe(tester);
    await tester.drag(
      find.byKey(const ValueKey('test-live-metrics-scroll')),
      const Offset(0, 520),
    );
    await tester.pumpAndSettle();
    expect(_sheetSize(tester), closeTo(0, 0.001));
  });

  testWidgets('reduced motion opens without waiting for an animation',
      (tester) async {
    await _pumpOverlay(tester, disableAnimations: true);

    await tester.timedDrag(
      find.byKey(const ValueKey('test-live-metrics-dashboard-scroll')),
      const Offset(0, -72),
      const Duration(milliseconds: 500),
    );
    await tester.pump();

    expect(_sheetSize(tester), closeTo(1, 0.001));
  });

  testWidgets('foreground builder can open the existing live sheet',
      (tester) async {
    await _pumpOverlay(tester, showOpenButton: true);

    await tester.tap(find.byKey(const ValueKey('test-foreground-open')));
    await tester.pumpAndSettle();

    expect(_sheetSize(tester), closeTo(1, 0.001));
  });

  testWidgets('downward dashboard overscroll still triggers refresh',
      (tester) async {
    var refreshCount = 0;
    await _pumpOverlay(
      tester,
      onRefresh: () => refreshCount++,
    );

    await tester.fling(
      find.byKey(const ValueKey('test-live-metrics-dashboard-scroll')),
      const Offset(0, 420),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshCount, 1);
    expect(_sheetSize(tester), closeTo(0, 0.001));
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  bool disableAnimations = false,
  VoidCallback? onRefresh,
  bool showOpenButton = false,
}) {
  final overlay = ThermostatLiveMetricsOverlay(
    dashboard: CustomScrollView(
      key: const ValueKey('test-live-metrics-dashboard-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: ColoredBox(color: Colors.blue),
        ),
      ],
    ),
    contentBuilder: (
      context,
      scrollController,
      close,
      titleFocusNode,
    ) {
      return Material(
        key: const ValueKey('test-live-metrics-content'),
        color: Colors.black,
        child: CustomScrollView(
          key: const ValueKey('test-live-metrics-scroll'),
          controller: scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: SafeArea(
                child: Row(
                  children: [
                    const Expanded(child: Text('Live content')),
                    IconButton(
                      key: const ValueKey('test-live-metrics-close'),
                      onPressed: close,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.shrink(),
            ),
          ],
        ),
      );
    },
    foregroundBuilder: showOpenButton
        ? (context, interactionController) {
            return Align(
              alignment: Alignment.topCenter,
              child: FilledButton(
                key: const ValueKey('test-foreground-open'),
                onPressed: interactionController.open,
                child: const Text('Open'),
              ),
            );
          }
        : null,
  );
  final body = onRefresh == null
      ? overlay
      : RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: overlay,
        );

  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 600),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: body,
        ),
      ),
    ),
  );
}

Future<void> _openWithSwipe(WidgetTester tester) async {
  await tester.timedDrag(
    find.byKey(const ValueKey('test-live-metrics-dashboard-scroll')),
    const Offset(0, -72),
    const Duration(milliseconds: 500),
  );
  await tester.pumpAndSettle();
  expect(_sheetSize(tester), closeTo(1, 0.001));
}

double _sheetSize(WidgetTester tester) {
  final sheet = tester.widget<DraggableScrollableSheet>(
    find.byKey(const ValueKey('thermostat-live-metrics-draggable-sheet')),
  );
  return sheet.controller!.size;
}
