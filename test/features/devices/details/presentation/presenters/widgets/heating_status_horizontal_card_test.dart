import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/heating_status_horizontal_card.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('shows ON and OFF with localized live semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    final harness = await _pumpCard(tester, value: true);

    expect(find.text('ON'), findsOneWidget);
    expect(find.bySemanticsLabel('Heating on'), findsOneWidget);
    final activeDecoration = _cardDecoration(tester);
    expect(activeDecoration.gradient, isNull);
    expect(
      activeDecoration.boxShadow,
      everyElement(
        isA<BoxShadow>().having(
          (shadow) => shadow.offset,
          'centered offset',
          Offset.zero,
        ),
      ),
    );

    harness.facade.emit(_snapshot(false));
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsOneWidget);
    expect(find.bySemanticsLabel('Heating off'), findsOneWidget);
    final inactiveDecoration = _cardDecoration(tester);
    expect(inactiveDecoration.gradient, isNull);
    expect(inactiveDecoration.boxShadow, isNull);
    expect(inactiveDecoration.color, isNot(activeDecoration.color));
    semantics.dispose();
  });

  testWidgets('shows unavailable state without treating it as OFF',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester, value: 'unknown');

    expect(find.text('—'), findsOneWidget);
    expect(find.text('OFF'), findsNothing);
    expect(
      find.bySemanticsLabel('Heating status unavailable'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('fires tap callback and disables status animations',
      (tester) async {
    var taps = 0;
    await _pumpCard(
      tester,
      value: true,
      disableAnimations: true,
      onTap: () => taps += 1,
    );

    await tester.tap(
      find.byKey(const ValueKey('heating-status-horizontal-card')),
    );
    await tester.pump();

    expect(taps, 1);
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('heating-status-horizontal-icon')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedSwitcher>(
            find.byKey(const ValueKey('heating-status-horizontal-value')),
          )
          .duration,
      Duration.zero,
    );
  });

  testWidgets('stays overflow-safe in dark mode with large text',
      (tester) async {
    await _pumpCard(
      tester,
      value: false,
      brightness: Brightness.dark,
      textScale: 2,
      width: 280,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('OFF'), findsOneWidget);
  });
}

Future<
    ({
      DeviceSnapshotCubit cubit,
      _HeatingStatusTestFacade facade,
    })> _pumpCard(
  WidgetTester tester, {
  required Object? value,
  bool disableAnimations = false,
  VoidCallback? onTap,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  double width = 360,
}) async {
  final facade = _HeatingStatusTestFacade(_snapshot(value));
  final cubit = DeviceSnapshotCubit(facade: facade)..start();
  addTearDown(facade.close);
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: Center(
          child: BlocProvider<DeviceSnapshotCubit>.value(
            value: cubit,
            child: SizedBox(
              width: width,
              height: 96,
              child: HeatingStatusHorizontalCard(
                bind: 'heaterEnabled',
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return (cubit: cubit, facade: facade);
}

BoxDecoration _cardDecoration(WidgetTester tester) {
  return tester
      .widget<AnimatedContainer>(
        find.byKey(const ValueKey('heating-status-horizontal-card')),
      )
      .decoration as BoxDecoration;
}

DeviceSnapshot _snapshot(Object? heatingState) {
  return DeviceSnapshot.initial(device: _device()).copyWith(
    controlState: DeviceSlice<Map<String, dynamic>>.ready(
      data: <String, dynamic>{'heaterEnabled': heatingState},
    ),
  );
}

Device _device() {
  return Device(
    id: 'device-1',
    sn: 'SN-1',
    modelId: 'model',
    modelName: 'Model',
    userData: const DeviceUserData(alias: 'Device', description: ''),
    connectionInfo: ConnectionInfo(online: true),
  );
}

final class _HeatingStatusTestFacade implements DeviceFacade {
  _HeatingStatusTestFacade(this._current);

  final StreamController<DeviceSnapshot> _controller =
      StreamController<DeviceSnapshot>.broadcast();
  DeviceSnapshot _current;

  @override
  DeviceSnapshot get current => _current;

  void emit(DeviceSnapshot snapshot) {
    _current = snapshot;
    _controller.add(snapshot);
  }

  @override
  Stream<DeviceSnapshot> watch() => _controller.stream;

  Future<void> close() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
