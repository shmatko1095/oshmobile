import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_user_properties.dart';

void main() {
  late _FakeAnalyticsBackend backend;

  setUp(() {
    backend = _FakeAnalyticsBackend();
    OshAnalytics.debugSetBackend(backend);
  });

  tearDown(OshAnalytics.debugResetBackend);

  test('logEvent delegates normalized parameters to backend', () async {
    await OshAnalytics.logEvent(
      'device_selected',
      parameters: {
        'online': true,
        'count': 2,
        'ratio': 1.5,
        'label': '  test  ',
        'ignored': null,
        'empty': '   ',
      },
    );

    expect(backend.loggedEvents, hasLength(1));
    expect(backend.loggedEvents.single.name, 'device_selected');
    expect(backend.loggedEvents.single.parameters, <String, Object>{
      'online': 1,
      'count': 2,
      'ratio': 1.5,
      'label': 'test',
    });
  });

  test('resetSessionContext clears analytics identity properties', () async {
    await OshAnalytics.resetSessionContext();

    expect(backend.userIds, <String?>[null]);
    expect(
      backend.userProperties,
      containsAll(<_UserPropertyCall>[
        const _UserPropertyCall(
          OshAnalyticsUserProperties.sessionMode,
          null,
        ),
        const _UserPropertyCall(
          OshAnalyticsUserProperties.authProvider,
          null,
        ),
      ]),
    );
  });

  test('logScreenView delegates to backend', () async {
    await OshAnalytics.logScreenView(
      screenName: 'device_dashboard',
      screenClass: 'MaterialPageRoute<dynamic>',
      parameters: {'device_layout': 'thermostat_basic'},
    );

    expect(backend.screenViews, hasLength(1));
    expect(backend.screenViews.single.screenName, 'device_dashboard');
    expect(
        backend.screenViews.single.screenClass, 'MaterialPageRoute<dynamic>');
    expect(
      backend.screenViews.single.parameters,
      <String, Object>{'device_layout': 'thermostat_basic'},
    );
  });

  test('setCollectionEnabled swallows backend failures', () async {
    backend.throwOnCollectionToggle = true;

    await expectLater(
      OshAnalytics.setCollectionEnabled(true),
      completes,
    );

    expect(backend.collectionEnabledCalls, 1);
  });
}

final class _FakeAnalyticsBackend implements AnalyticsBackend {
  final List<_LoggedEvent> loggedEvents = <_LoggedEvent>[];
  final List<_ScreenViewCall> screenViews = <_ScreenViewCall>[];
  final List<String?> userIds = <String?>[];
  final List<_UserPropertyCall> userProperties = <_UserPropertyCall>[];

  int collectionEnabledCalls = 0;
  bool throwOnCollectionToggle = false;

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    loggedEvents.add(_LoggedEvent(name, parameters));
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {
    screenViews.add(_ScreenViewCall(screenName, screenClass, parameters));
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabledCalls++;
    if (throwOnCollectionToggle) {
      throw TimeoutException('analytics toggle failed');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    userIds.add(userId);
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    userProperties.add(_UserPropertyCall(name, value));
  }
}

final class _LoggedEvent {
  const _LoggedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object?>? parameters;
}

final class _ScreenViewCall {
  const _ScreenViewCall(this.screenName, this.screenClass, this.parameters);

  final String screenName;
  final String? screenClass;
  final Map<String, Object?>? parameters;
}

final class _UserPropertyCall {
  const _UserPropertyCall(this.name, this.value);

  final String name;
  final String? value;

  @override
  bool operator ==(Object other) {
    return other is _UserPropertyCall &&
        other.name == name &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(name, value);
}
