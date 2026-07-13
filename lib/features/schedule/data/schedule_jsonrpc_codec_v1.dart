part of 'schedule_jsonrpc_codec.dart';

final class ScheduleJsonRpcCodecV1 extends _ScheduleJsonRpcCodecBase {
  const ScheduleJsonRpcCodecV1._(super.validator);

  static const _unchecked =
      ScheduleJsonRpcCodecV1._(SchedulePayloadValidator());

  static const _supportedSetpointKinds = <ScheduleSetpointKind>{
    ScheduleSetpointKind.temperature,
  };

  @override
  Set<ScheduleSetpointKind> get supportedSetpointKinds =>
      _supportedSetpointKinds;

  /// Decodes trusted V1 state without applying a runtime JSON schema first.
  static CalendarSnapshot? decodeBodyUnchecked(Map<String, dynamic> data) {
    return _unchecked._decodeBodyUnchecked(data);
  }

  /// Encodes trusted local state with V1 runtime points included.
  static Map<String, dynamic> encodeBodyUnchecked(CalendarSnapshot snapshot) {
    return _unchecked._encodeBodyUnchecked(snapshot);
  }

  /// Encodes a trusted V1 patch without runtime JSON Schema validation.
  static Map<String, dynamic> encodePatchUnchecked({
    CalendarMode? mode,
    Map<CalendarMode, List<SchedulePoint>>? points,
    ScheduleRange? range,
  }) {
    return _unchecked._encodePatchUnchecked(
      mode: mode,
      points: points,
      range: range,
    );
  }

  @override
  SchedulePoint? decodePoint(dynamic raw) {
    if (raw is! Map) return null;
    final temperature = (raw['temp'] as num?)?.toDouble();
    if (temperature == null) return null;
    return _pointWithSetpoint(
      raw,
      ScheduleSetpoint.temperature(_roundTemperature(temperature)),
    );
  }

  @override
  Map<String, dynamic> encodePoint(SchedulePoint point) {
    if (!point.setpoint.isTemperature) {
      throw const FormatException(
        'schedule@1 only supports temperature setpoints',
      );
    }
    return <String, dynamic>{
      'temp': _roundTemperature(point.setpoint.temperature!),
      ..._encodePointCoordinates(point),
    };
  }
}
