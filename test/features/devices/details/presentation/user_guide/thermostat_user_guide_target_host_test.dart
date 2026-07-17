import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/devices/details/presentation/user_guide/thermostat_user_guide_target_host.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';

import '../../../../user_guide/test_user_guide_progress_repository.dart';

void main() {
  testWidgets('unregistering the final host finishes its manual session',
      (tester) async {
    final registry = UserGuideHostRegistry();
    final cubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ThermostatUserGuideTargetHost(
          registry: registry,
          cubit: cubit,
          enabled: true,
          builder: (context, temperatureTargetKey, modeBarTargetKey) {
            return const SizedBox.expand();
          },
        ),
      ),
    );

    expect(
      registry.hasHost(UserGuideTopic.thermostatLiveMetricsV1),
      isTrue,
    );
    cubit.startManualGuide();

    await tester.pumpWidget(const SizedBox.shrink());

    expect(
      registry.hasHost(UserGuideTopic.thermostatLiveMetricsV1),
      isFalse,
    );
    expect(cubit.state.isManualSessionActive, isFalse);
  });

  testWidgets('disabling the final host finishes its manual session',
      (tester) async {
    final registry = UserGuideHostRegistry();
    final cubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();

    Widget buildHost({required bool enabled}) {
      return MaterialApp(
        home: ThermostatUserGuideTargetHost(
          registry: registry,
          cubit: cubit,
          enabled: enabled,
          builder: (context, temperatureTargetKey, modeBarTargetKey) {
            return const SizedBox.expand();
          },
        ),
      );
    }

    await tester.pumpWidget(buildHost(enabled: true));
    cubit.startManualGuide();

    await tester.pumpWidget(buildHost(enabled: false));

    expect(
      registry.hasHost(UserGuideTopic.thermostatLiveMetricsV1),
      isFalse,
    );
    expect(cubit.state.isManualSessionActive, isFalse);
  });

  testWidgets(
      'removing the final host cancels automatic session without completion',
      (tester) async {
    final registry = UserGuideHostRegistry();
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ThermostatUserGuideTargetHost(
          registry: registry,
          cubit: cubit,
          enabled: true,
          builder: (context, temperatureTargetKey, modeBarTargetKey) {
            return const SizedBox.expand();
          },
        ),
      ),
    );
    cubit.startAutomaticGuide();
    cubit.selectPage(2);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(cubit.state.isGuideSessionActive, isFalse);
    expect(cubit.state.completedTopics, isEmpty);
    expect(cubit.state.sessionSuppressedTopics, isEmpty);
    expect(repository.saveCount, 0);
  });
}
