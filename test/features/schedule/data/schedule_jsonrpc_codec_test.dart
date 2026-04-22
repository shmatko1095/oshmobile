import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/contracts/json_rpc_contract_descriptor.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

void main() {
  group('ScheduleJsonRpcCodec', () {
    test('decodeBodyUnchecked reads current_point and next_point', () {
      final snapshot = ScheduleJsonRpcCodec.decodeBodyUnchecked({
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
      final snapshot = ScheduleJsonRpcCodec.decodeBodyUnchecked({
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

      final encoded = ScheduleJsonRpcCodec.encodeBodyUnchecked(snapshot);
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
