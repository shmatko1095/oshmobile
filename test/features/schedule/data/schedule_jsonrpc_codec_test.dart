import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/contracts/json_rpc_contract_descriptor.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

void main() {
  group('ScheduleJsonRpcCodec', () {
    test('factory selects the implementation for the negotiated major', () {
      expect(
        ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContract),
        isA<ScheduleJsonRpcCodecV1>(),
      );
      expect(
        ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContractV2),
        isA<ScheduleJsonRpcCodecV2>(),
      );
    });

    test('factory rejects an unsupported major', () {
      expect(
        () => ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContractV3),
        throwsUnsupportedError,
      );
    });

    test('each implementation exposes its supported setpoint kinds', () {
      expect(
        ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContract)
            .supportedSetpointKinds,
        const <ScheduleSetpointKind>{ScheduleSetpointKind.temperature},
      );
      expect(
        ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContractV2)
            .supportedSetpointKinds,
        const <ScheduleSetpointKind>{
          ScheduleSetpointKind.temperature,
          ScheduleSetpointKind.on,
          ScheduleSetpointKind.off,
        },
      );
    });

    test('decodeBodyUnchecked reads current_point and next_point', () {
      final snapshot = ScheduleJsonRpcCodecV1.decodeBodyUnchecked({
        'mode': 'daily',
        'points': {
          'off': [],
          'on': [],
          'daily': [
            {'temp': 5.0, 'hh': 0, 'mm': 0, 'mask': 127},
          ],
          'weekly': [],
          'range': {'min': 15.0, 'max': 25.0},
        },
        'current_point': {'temp': 35.0, 'hh': 14, 'mm': 0, 'mask': 127},
        'next_point': {'temp': 5.0, 'hh': 16, 'mm': 0, 'mask': 127},
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.currentPoint?.temp, 35.0);
      expect(snapshot.currentPoint?.time, const TimeOfDay(hour: 14, minute: 0));
      expect(snapshot.nextPoint?.temp, 5.0);
      expect(snapshot.nextPoint?.time, const TimeOfDay(hour: 16, minute: 0));
    });

    test('decodeBodyUnchecked keeps points null when fields are absent', () {
      final snapshot = ScheduleJsonRpcCodecV1.decodeBodyUnchecked({
        'mode': 'daily',
        'points': {
          'off': [],
          'on': [],
          'daily': [
            {'temp': 7.0, 'hh': 3, 'mm': 30, 'mask': 127},
          ],
          'weekly': [],
          'range': {'min': 15.0, 'max': 25.0},
        },
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.currentPoint, isNull);
      expect(snapshot.nextPoint, isNull);
    });

    test('encodeBodyUnchecked includes current_point and next_point for state',
        () {
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.daily,
        lists: {
          CalendarMode.daily: const [
            SchedulePoint(
              time: TimeOfDay(hour: 3, minute: 0),
              daysMask: WeekdayMask.all,
              temp: 21.0,
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

      final encoded = ScheduleJsonRpcCodecV1.encodeBodyUnchecked(snapshot);
      expect(encoded['current_point'], {
        'temp': 35.0,
        'hh': 14,
        'mm': 0,
        'mask': 127,
      });
      expect(encoded['next_point'], {
        'temp': 5.0,
        'hh': 16,
        'mm': 0,
        'mask': 127,
      });
    });

    test('encodeBody excludes current_point and next_point for set payload',
        () {
      final codec = ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContract);
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.daily,
        lists: const {},
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

      final encoded = codec.encodeBody(snapshot);
      expect(encoded.containsKey('current_point'), isFalse);
      expect(encoded.containsKey('next_point'), isFalse);
      expect(encoded['mode'], CalendarMode.daily.id);
      expect(encoded['points'], isA<Map<String, dynamic>>());
    });

    test('schedule@2 decodes temperature, ON and OFF setpoints', () {
      final snapshot = ScheduleJsonRpcCodecV2.decodeBodyUnchecked({
        'mode': 'daily',
        'points': {
          'off': [],
          'on': [],
          'daily': [
            {
              'kind': 'temperature',
              'temp': 21.5,
              'hh': 6,
              'mm': 0,
              'mask': 127,
            },
            {'kind': 'on', 'hh': 8, 'mm': 0, 'mask': 127},
            {'kind': 'off', 'hh': 22, 'mm': 0, 'mask': 127},
          ],
          'weekly': [],
          'range': {'min': 15.0, 'max': 25.0},
        },
        'current_point': {'kind': 'on', 'hh': 8, 'mm': 0, 'mask': 127},
        'next_point': {'kind': 'off', 'hh': 22, 'mm': 0, 'mask': 127},
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.pointsFor(CalendarMode.daily)[0].setpoint.temperature,
          21.5);
      expect(snapshot.pointsFor(CalendarMode.daily)[1].setpoint.isOn, isTrue);
      expect(snapshot.pointsFor(CalendarMode.daily)[2].setpoint.isOff, isTrue);
      expect(snapshot.currentPoint?.setpoint.isOn, isTrue);
      expect(snapshot.nextPoint?.setpoint.isOff, isTrue);
      expect(snapshot.range, const ScheduleRange(min: 15.0, max: 25.0));
    });

    test('schedule@2 encodes ON/OFF without temp and temperature with temp',
        () {
      final codec =
          ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContractV2);
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.daily,
        lists: {
          CalendarMode.daily: [
            SchedulePoint.withSetpoint(
              time: const TimeOfDay(hour: 6, minute: 0),
              daysMask: WeekdayMask.all,
              setpoint: const ScheduleSetpoint.temperature(21.5),
            ),
            SchedulePoint.withSetpoint(
              time: const TimeOfDay(hour: 8, minute: 0),
              daysMask: WeekdayMask.all,
              setpoint: const ScheduleSetpoint.on(),
            ),
            SchedulePoint.withSetpoint(
              time: const TimeOfDay(hour: 22, minute: 0),
              daysMask: WeekdayMask.all,
              setpoint: const ScheduleSetpoint.off(),
            ),
          ],
        },
        range: const ScheduleRange(min: 15.0, max: 25.0),
      );

      final encoded = codec.encodeBody(snapshot);
      final daily = (encoded['points'] as Map)['daily'] as List;
      expect(daily[0], {
        'kind': 'temperature',
        'temp': 21.5,
        'hh': 6,
        'mm': 0,
        'mask': 127,
      });
      expect(daily[1], {
        'kind': 'on',
        'hh': 8,
        'mm': 0,
        'mask': 127,
      });
      expect(daily[2], {
        'kind': 'off',
        'hh': 22,
        'mm': 0,
        'mask': 127,
      });
      expect((encoded['points'] as Map)['range'], {
        'min': 15.0,
        'max': 25.0,
      });
    });

    test('schedule@1 rejects ON/OFF writes', () {
      final codec = ScheduleJsonRpcCodec.fromRuntimeContract(_runtimeContract);
      final snapshot = CalendarSnapshot(
        mode: CalendarMode.on,
        lists: {
          CalendarMode.on: [
            SchedulePoint.withSetpoint(
              time: const TimeOfDay(hour: 0, minute: 0),
              daysMask: WeekdayMask.all,
              setpoint: const ScheduleSetpoint.on(),
            ),
          ],
        },
      );

      expect(() => codec.encodeBody(snapshot), throwsFormatException);
    });
  });
}

final RuntimeDomainContract _runtimeContract = RuntimeDomainContract(
  read: _descriptor,
  patch: _descriptor,
  set: _descriptor,
  stateSchema: const {
    'type': 'object',
    'required': ['mode', 'points'],
    'properties': {
      'mode': {'type': 'string'},
      'points': {'type': 'object'},
    },
  },
  patchSchema: const {
    'type': 'object',
    'properties': {
      'mode': {'type': 'string'},
      'points': {'type': 'object'},
    },
  },
  setSchema: const {
    'type': 'object',
    'additionalProperties': false,
    'required': ['mode', 'points'],
    'properties': {
      'mode': {'type': 'string'},
      'points': {'type': 'object'},
    },
  },
);

const JsonRpcContractDescriptor _descriptor = JsonRpcContractDescriptor(
  methodDomain: 'schedule',
  schemaDomain: 'schedule',
  major: 1,
);

final RuntimeDomainContract _runtimeContractV2 = RuntimeDomainContract(
  read: _descriptorV2,
  patch: _descriptorV2,
  set: _descriptorV2,
  stateSchema: _runtimeContract.stateSchema,
  patchSchema: _runtimeContract.patchSchema,
  setSchema: _runtimeContract.setSchema,
);

const JsonRpcContractDescriptor _descriptorV2 = JsonRpcContractDescriptor(
  methodDomain: 'schedule',
  schemaDomain: 'schedule',
  major: 2,
);

final RuntimeDomainContract _runtimeContractV3 = RuntimeDomainContract(
  read: _descriptorV3,
  patch: _descriptorV3,
  set: _descriptorV3,
  stateSchema: _runtimeContract.stateSchema,
  patchSchema: _runtimeContract.patchSchema,
  setSchema: _runtimeContract.setSchema,
);

const JsonRpcContractDescriptor _descriptorV3 = JsonRpcContractDescriptor(
  methodDomain: 'schedule',
  schemaDomain: 'schedule',
  major: 3,
);
