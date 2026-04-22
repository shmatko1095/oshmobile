import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/control_state_resolver.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
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
  });
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
