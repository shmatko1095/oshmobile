import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/utils/schedule_point_defaults.dart';

void main() {
  group('stepScheduleSetpoint', () {
    test('steps symmetrically across OFF and minimum temperature', () {
      expect(
        stepScheduleSetpoint(
          const ScheduleSetpoint.off(),
          0.5,
          supportedSetpointKinds: _typedSetpointKinds,
        ),
        const ScheduleSetpoint.temperature(10.0),
      );
      expect(
        stepScheduleSetpoint(
          const ScheduleSetpoint.temperature(10.0),
          -0.5,
          supportedSetpointKinds: _typedSetpointKinds,
        ),
        const ScheduleSetpoint.off(),
      );
    });

    test('steps symmetrically across maximum temperature and ON', () {
      expect(
        stepScheduleSetpoint(
          const ScheduleSetpoint.temperature(40.0),
          0.5,
          supportedSetpointKinds: _typedSetpointKinds,
        ),
        const ScheduleSetpoint.on(),
      );
      expect(
        stepScheduleSetpoint(
          const ScheduleSetpoint.on(),
          -0.5,
          supportedSetpointKinds: _typedSetpointKinds,
        ),
        const ScheduleSetpoint.temperature(40.0),
      );
    });

    test('temperature-only capability clamps to temperature bounds', () {
      expect(
        stepScheduleSetpoint(
          const ScheduleSetpoint.temperature(10.0),
          -0.5,
          supportedSetpointKinds: _temperatureOnlySetpointKinds,
        ),
        const ScheduleSetpoint.temperature(10.0),
      );
      expect(
        stepScheduleSetpoint(
          const ScheduleSetpoint.temperature(40.0),
          0.5,
          supportedSetpointKinds: _temperatureOnlySetpointKinds,
        ),
        const ScheduleSetpoint.temperature(40.0),
      );
    });
  });

  group('makeDefaultSchedulePoint', () {
    test('defaults to 21 degrees without a previous point', () {
      final point = makeDefaultSchedulePoint(const [], CalendarMode.daily);
      expect(point.setpoint, const ScheduleSetpoint.temperature(21.0));
    });

    test('inherits the previous ON/OFF setpoint', () {
      final previous = SchedulePoint.withSetpoint(
        time: const TimeOfDay(hour: 8, minute: 0),
        daysMask: WeekdayMask.all,
        setpoint: const ScheduleSetpoint.on(),
      );
      final point = makeDefaultSchedulePoint([previous], CalendarMode.daily);
      expect(point.setpoint, const ScheduleSetpoint.on());
    });
  });
}

const _temperatureOnlySetpointKinds = <ScheduleSetpointKind>{
  ScheduleSetpointKind.temperature,
};

const _typedSetpointKinds = <ScheduleSetpointKind>{
  ScheduleSetpointKind.temperature,
  ScheduleSetpointKind.on,
  ScheduleSetpointKind.off,
};
