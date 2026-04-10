import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/features/devices/no_selected_device/presentation/pages/no_selected_device_page.dart';

void main() {
  setUp(() {
    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
  });

  tearDown(() {
    OshAnalytics.debugResetBackend();
  });

  testWidgets('renders contextual message and triggers CTA',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoSelectedDevicePage(
            title: 'No device selected',
            subtitle: 'Choose a device to view the dashboard and settings.',
            actionLabel: 'Open devices',
            onActionPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No device selected'), findsOneWidget);
    expect(
      find.text('Choose a device to view the dashboard and settings.'),
      findsOneWidget,
    );
    expect(find.text('Open devices'), findsOneWidget);

    await tester.tap(find.text('Open devices'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}

class _NoopAnalyticsBackend implements AnalyticsBackend {
  const _NoopAnalyticsBackend();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {}
}
