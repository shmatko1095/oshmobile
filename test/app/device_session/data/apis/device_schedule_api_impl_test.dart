import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/data/apis/device_schedule_api_impl.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/control_state_resolver.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

void main() {
  test('optimistic schedule overrides clear device-derived current/next points',
      () async {
    final repo = _FakeScheduleRepository();
    final api = DeviceScheduleApiImpl(
      deviceSn: 'device-1',
      repo: repo,
      comm: MqttCommCubit(),
      onChanged: () {},
    );

    await api.start();
    repo.emit(
      CalendarSnapshot(
        mode: CalendarMode.daily,
        lists: {
          CalendarMode.daily: const [
            SchedulePoint(
              time: TimeOfDay(hour: 0, minute: 0),
              daysMask: WeekdayMask.all,
              temp: 10.0,
            ),
          ],
        },
        currentPoint: const SchedulePoint(
          time: TimeOfDay(hour: 14, minute: 0),
          daysMask: WeekdayMask.all,
          temp: 35.0,
        ),
        nextPoint: const SchedulePoint(
          time: TimeOfDay(hour: 16, minute: 0),
          daysMask: WeekdayMask.all,
          temp: 5.0,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(api.current?.currentPoint?.temp, 35.0);
    expect(api.current?.nextPoint?.temp, 5.0);

    api.patchList(
      CalendarMode.daily,
      const [
        SchedulePoint(
          time: TimeOfDay(hour: 3, minute: 45),
          daysMask: WeekdayMask.all,
          temp: 22.0,
        ),
      ],
    );

    final merged = api.current;
    expect(merged, isNotNull);
    expect(merged!.currentPoint, isNull);
    expect(merged.nextPoint, isNull);

    final resolver = ControlStateResolver();
    final bundle = _bundleWithScheduleTargetControls();
    final state = resolver.resolveAll(
      registry: ControlRegistry(bundle),
      controlIds: bundle.configuration.oshmobile.controls.keys,
      schedule: merged,
    );

    expect(state['schedule_current'], 22.0);
    expect(state['schedule_next'], {
      'temp': 22.0,
      'hour': 3,
      'minute': 45,
    });

    await api.dispose();
    await repo.dispose();
  });
}

class _FakeScheduleRepository implements ScheduleRepository {
  final StreamController<CalendarSnapshot> _controller =
      StreamController<CalendarSnapshot>.broadcast();

  void emit(CalendarSnapshot snapshot) => _controller.add(snapshot);

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<CalendarSnapshot> fetchAll({bool forceGet = false}) async {
    throw UnimplementedError('Not used in this test');
  }

  @override
  Future<void> saveAll(CalendarSnapshot snapshot, {String? reqId}) async {}

  @override
  Future<void> setMode(CalendarMode mode, {String? reqId}) async {}

  @override
  Stream<CalendarSnapshot> watchSnapshot() => _controller.stream;
}

DeviceConfigurationBundle _bundleWithScheduleTargetControls() {
  final bundle = DeviceConfigurationBundle.fromJson({
    'configuration_id': 'cfg',
    'model_id': 'model',
    'revision': 1,
    'status': 'approved',
    'firmware_version': '1.0.0',
    'configuration': {
      'schema_version': 1,
      'integrations': {
        'oshmobile': {
          'layout': 'test',
          'domains': {
            'schedule': {'contract_id': 'schedule@1'},
          },
          'widgets': const [],
          'settings_groups': const [],
          'collections': const [],
          'controls': const [
            {
              'id': 'schedule_current',
              'title': 'Current target',
              'read': {'kind': 'schedule_current_target'},
            },
            {
              'id': 'schedule_next',
              'title': 'Next target',
              'read': {'kind': 'schedule_next_target'},
            },
          ],
        },
      },
    },
    'runtime_contracts': const [],
  });

  return bundle.copyWith(readableDomains: const {'schedule'});
}
