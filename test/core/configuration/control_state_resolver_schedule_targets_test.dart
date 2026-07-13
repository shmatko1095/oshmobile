import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/control_state_resolver.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/contracts/json_rpc_contract_descriptor.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

void main() {
  group('ControlStateResolver schedule targets', () {
    final resolver = ControlStateResolver();
    final bundle = _bundleWithScheduleTargetControls();
    final registry = ControlRegistry(bundle);
    final controlIds = bundle.configuration.oshmobile.controls.keys;

    test('prefers current_point and next_point from schedule payload', () {
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.daily,
        lists: {
          CalendarMode.daily: const [
            SchedulePoint(
              time: TimeOfDay(hour: 1, minute: 0),
              daysMask: WeekdayMask.all,
              temp: 8.0,
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
      );

      final state = resolver.resolveAll(
        registry: registry,
        controlIds: controlIds,
        schedule: snapshot,
      );

      expect(state['schedule_current'], 35.0);
      expect(state['schedule_next'], {
        'temp': 5.0,
        'hour': 16,
        'minute': 0,
      });
    });

    test('falls back to legacy resolve when current/next are absent', () {
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.daily,
        lists: {
          CalendarMode.daily: const [
            SchedulePoint(
              time: TimeOfDay(hour: 3, minute: 45),
              daysMask: WeekdayMask.all,
              temp: 22.0,
            ),
          ],
        },
      );

      final state = resolver.resolveAll(
        registry: registry,
        controlIds: controlIds,
        schedule: snapshot,
      );

      expect(state['schedule_current'], 22.0);
      expect(state['schedule_next'], {
        'temp': 22.0,
        'hour': 3,
        'minute': 45,
      });
    });

    test('resolves ON/OFF current and next setpoints', () {
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.daily,
        lists: const {},
        currentPoint: SchedulePoint.withSetpoint(
          time: const TimeOfDay(hour: 8, minute: 0),
          daysMask: WeekdayMask.all,
          setpoint: const ScheduleSetpoint.on(),
        ),
        nextPoint: SchedulePoint.withSetpoint(
          time: const TimeOfDay(hour: 22, minute: 0),
          daysMask: WeekdayMask.all,
          setpoint: const ScheduleSetpoint.off(),
        ),
      );

      final state = resolver.resolveAll(
        registry: registry,
        controlIds: controlIds,
        schedule: snapshot,
      );

      expect(state['schedule_current'], 'ON');
      expect(state['schedule_next'], {
        'kind': 'off',
        'setpoint': 'OFF',
        'hour': 22,
        'minute': 0,
      });
    });

    test('serializes schedule bindings with the codec selected by resolve', () {
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.on,
        lists: {
          CalendarMode.on: [
            SchedulePoint.withSetpoint(
              time: const TimeOfDay(hour: 8, minute: 0),
              daysMask: WeekdayMask.all,
              setpoint: const ScheduleSetpoint.on(),
            ),
          ],
        },
      );
      final v2Bundle = _bundleWithSchedulePointsControl(contractMajor: 2);

      final state = resolver.resolveAll(
        registry: ControlRegistry(v2Bundle),
        controlIds: v2Bundle.configuration.oshmobile.controls.keys,
        schedule: snapshot,
        scheduleCodec: ScheduleJsonRpcCodec.fromRuntimeContract(
          _scheduleRuntimeContract(major: 2),
        ),
      );

      expect(state['schedule_points'], [
        {
          'kind': 'on',
          'hh': 8,
          'mm': 0,
          'mask': WeekdayMask.all,
        },
      ]);
    });

    test('contains an incompatible V1 schedule without breaking other state',
        () {
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.on,
        lists: {
          CalendarMode.on: [
            SchedulePoint.withSetpoint(
              time: const TimeOfDay(hour: 8, minute: 0),
              daysMask: WeekdayMask.all,
              setpoint: const ScheduleSetpoint.on(),
            ),
          ],
        },
      );
      final v1Bundle = _bundleWithSchedulePointsControl(contractMajor: 1);

      final state = resolver.resolveAll(
        registry: ControlRegistry(v1Bundle),
        controlIds: v1Bundle.configuration.oshmobile.controls.keys,
        schedule: snapshot,
        scheduleCodec: ScheduleJsonRpcCodec.fromRuntimeContract(
          _scheduleRuntimeContract(major: 1),
        ),
      );

      expect(state, isNot(contains('schedule_points')));
    });
  });
}

RuntimeDomainContract _scheduleRuntimeContract({required int major}) {
  final descriptor = JsonRpcContractDescriptor(
    methodDomain: 'schedule',
    schemaDomain: 'schedule',
    major: major,
  );
  return RuntimeDomainContract(
    read: descriptor,
    patch: descriptor,
    set: descriptor,
    stateSchema: null,
    patchSchema: null,
    setSchema: null,
  );
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

DeviceConfigurationBundle _bundleWithSchedulePointsControl({
  required int contractMajor,
}) {
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
            'schedule': {'contract_id': 'schedule@$contractMajor'},
          },
          'widgets': const [],
          'settings_groups': const [],
          'collections': const [],
          'controls': const [
            {
              'id': 'schedule_points',
              'title': 'Schedule points',
              'read': {
                'kind': 'domain_path',
                'domain': 'schedule',
                'path': 'points.on',
              },
            },
          ],
        },
      },
    },
    'runtime_contracts': const [],
  });

  return bundle.copyWith(readableDomains: const {'schedule'});
}
