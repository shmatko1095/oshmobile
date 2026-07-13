import 'package:flutter/material.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/features/schedule/data/schedule_payload_validator.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

part 'schedule_jsonrpc_codec_base.dart';
part 'schedule_jsonrpc_codec_support.dart';
part 'schedule_jsonrpc_codec_v1.dart';
part 'schedule_jsonrpc_codec_v2.dart';

/// Version-aware codec for the schedule JSON-RPC domain.
///
/// The runtime contract selects exactly one wire implementation:
///
/// - [ScheduleJsonRpcCodecV1] reads and writes temperature-only points;
/// - [ScheduleJsonRpcCodecV2] reads and writes typed temperature/ON/OFF points.
abstract interface class ScheduleJsonRpcCodec {
  factory ScheduleJsonRpcCodec.fromRuntimeContract(
    RuntimeDomainContract contract,
  ) {
    final validator = SchedulePayloadValidator(
      stateSchema: contract.stateSchema,
      setSchema: contract.setSchema,
      patchSchema: contract.patchSchema,
    );

    return switch (contract.read.major) {
      1 => ScheduleJsonRpcCodecV1._(validator),
      2 => ScheduleJsonRpcCodecV2._(validator),
      final major => throw UnsupportedError(
          'Unsupported schedule contract major: $major',
        ),
    };
  }

  /// Setpoint kinds that this wire version can safely encode.
  Set<ScheduleSetpointKind> get supportedSetpointKinds;

  CalendarSnapshot? decodeBody(Map<String, dynamic> data);

  /// Encodes the locally held state for configuration-driven read bindings.
  ///
  /// Unlike [encodeBody], this includes runtime `current_point` and
  /// `next_point` and does not apply a write-payload schema.
  Map<String, dynamic> encodeStateBody(CalendarSnapshot snapshot);

  Map<String, dynamic> encodeBody(CalendarSnapshot snapshot);

  Map<String, dynamic> encodePatch({
    CalendarMode? mode,
    Map<CalendarMode, List<SchedulePoint>>? points,
    ScheduleRange? range,
  });
}
