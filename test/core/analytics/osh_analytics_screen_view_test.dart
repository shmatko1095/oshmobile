import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';

void main() {
  late _RecordingAnalyticsBackend backend;

  setUp(() {
    backend = _RecordingAnalyticsBackend();
    OshAnalytics.debugSetBackend(backend);
  });

  tearDown(OshAnalytics.debugResetBackend);

  testWidgets('screen view widget logs initial and updated screen names',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OshAnalyticsScreenView(
          screenName: 'sign_in',
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(backend.screenNames, <String>['sign_in']);

    await tester.pumpWidget(
      const MaterialApp(
        home: OshAnalyticsScreenView(
          screenName: 'home',
          child: SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();

    expect(backend.screenNames, <String>['sign_in', 'home']);
  });
}

final class _RecordingAnalyticsBackend implements AnalyticsBackend {
  final List<String> screenNames = <String>[];

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
  }) async {
    screenNames.add(screenName);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}
