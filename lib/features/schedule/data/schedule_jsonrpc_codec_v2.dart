part of 'schedule_jsonrpc_codec.dart';

final class ScheduleJsonRpcCodecV2 extends _ScheduleJsonRpcCodecBase {
  const ScheduleJsonRpcCodecV2._(super.validator);

  static const _unchecked =
      ScheduleJsonRpcCodecV2._(SchedulePayloadValidator());

  static const _supportedSetpointKinds = <ScheduleSetpointKind>{
    ScheduleSetpointKind.temperature,
    ScheduleSetpointKind.on,
    ScheduleSetpointKind.off,
  };

  @override
  Set<ScheduleSetpointKind> get supportedSetpointKinds =>
      _supportedSetpointKinds;

  /// Decodes trusted V2 state without applying a runtime JSON schema first.
  static CalendarSnapshot? decodeBodyUnchecked(Map<String, dynamic> data) {
    return _unchecked._decodeBodyUnchecked(data);
  }

  /// Encodes trusted local state with V2 runtime points included.
  static Map<String, dynamic> encodeBodyUnchecked(CalendarSnapshot snapshot) {
    return _unchecked._encodeBodyUnchecked(snapshot);
  }

  /// Encodes a trusted V2 patch without runtime JSON Schema validation.
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

    final ScheduleSetpoint setpoint;
    switch (raw['kind']) {
      case 'temperature':
        final temperature = (raw['temp'] as num?)?.toDouble();
        if (temperature == null) return null;
        setpoint = ScheduleSetpoint.temperature(
          _roundTemperature(temperature),
        );
      case 'on':
        if (raw.containsKey('temp')) return null;
        setpoint = const ScheduleSetpoint.on();
      case 'off':
        if (raw.containsKey('temp')) return null;
        setpoint = const ScheduleSetpoint.off();
      default:
        return null;
    }

    return _pointWithSetpoint(raw, setpoint);
  }

  @override
  Map<String, dynamic> encodePoint(SchedulePoint point) {
    return <String, dynamic>{
      'kind': point.setpoint.kind.name,
      if (point.setpoint.isTemperature)
        'temp': _roundTemperature(point.setpoint.temperature!),
      ..._encodePointCoordinates(point),
    };
  }
}
