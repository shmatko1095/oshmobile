import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/common/cubits/mqtt/global_mqtt_cubit.dart'
    as global_mqtt;
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/home/presentation/widgets/mqtt_activity_icon.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('hides indicator while status is online',
      (WidgetTester tester) async {
    final mqttCubit = _TestGlobalMqttCubit();
    final commCubit = MqttCommCubit();
    addTearDown(mqttCubit.close);
    addTearDown(commCubit.close);

    mqttCubit.emitState(const global_mqtt.MqttConnected());

    await _pumpMqttHarness(
      tester,
      mqttCubit: mqttCubit,
      commCubit: commCubit,
    );

    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    expect(find.byIcon(Icons.sync_rounded), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets('shows updating icon for pending commands',
      (WidgetTester tester) async {
    final mqttCubit = _TestGlobalMqttCubit();
    final commCubit = MqttCommCubit();
    addTearDown(mqttCubit.close);
    addTearDown(commCubit.close);

    mqttCubit.emitState(const global_mqtt.MqttConnected());
    commCubit.start(reqId: 'req-1', deviceSn: 'device-1');

    await _pumpMqttHarness(
      tester,
      mqttCubit: mqttCubit,
      commCubit: commCubit,
    );

    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RotationTransition &&
            widget.child is Icon &&
            (widget.child as Icon).icon == Icons.sync_rounded,
      ),
      findsOneWidget,
    );
    expect(find.text('Updating'), findsNothing);
  });

  testWidgets('shows error icon and does not open details on tap',
      (WidgetTester tester) async {
    final mqttCubit = _TestGlobalMqttCubit();
    final commCubit = MqttCommCubit();
    addTearDown(mqttCubit.close);
    addTearDown(commCubit.close);

    mqttCubit.emitState(const global_mqtt.MqttError('Broker timeout'));

    await _pumpMqttHarness(
      tester,
      mqttCubit: mqttCubit,
      commCubit: commCubit,
    );

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Error'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.byIcon(Icons.error_outline_rounded));
    await tester.pump();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Broker timeout'), findsNothing);
  });
}

Future<void> _pumpMqttHarness(
  WidgetTester tester, {
  required global_mqtt.GlobalMqttCubit mqttCubit,
  required MqttCommCubit commCubit,
}) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<global_mqtt.GlobalMqttCubit>.value(value: mqttCubit),
        BlocProvider<MqttCommCubit>.value(value: commCubit),
      ],
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: Center(
            child: MqttActivityIcon(),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
}

class _TestGlobalMqttCubit extends global_mqtt.GlobalMqttCubit {
  _TestGlobalMqttCubit() : super(mqttRepo: _FakeDeviceMqttRepo());

  void emitState(global_mqtt.GlobalMqttState state) => emit(state);
}

class _FakeDeviceMqttRepo implements DeviceMqttRepo {
  final StreamController<DeviceMqttConnEvent> _controller =
      StreamController<DeviceMqttConnEvent>.broadcast();

  @override
  bool get isConnected => false;

  @override
  Stream<DeviceMqttConnEvent> get connEvents => _controller.stream;

  @override
  Future<void> connect({required String userId, required String token}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> disposeSession() async {
    await _controller.close();
  }

  @override
  Future<bool> publishJson(
    String topic,
    Map<String, dynamic> payload, {
    int qos = 1,
    bool retain = false,
  }) async {
    return true;
  }

  @override
  Future<void> reconnect(
      {required String userId, required String token}) async {}

  @override
  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1}) {
    return const Stream<MqttJson>.empty();
  }
}
