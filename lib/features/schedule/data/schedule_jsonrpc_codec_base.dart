part of 'schedule_jsonrpc_codec.dart';

abstract class _ScheduleJsonRpcCodecBase implements ScheduleJsonRpcCodec {
  const _ScheduleJsonRpcCodecBase(this._validator);

  final SchedulePayloadValidator _validator;

  @override
  CalendarSnapshot? decodeBody(Map<String, dynamic> data) {
    if (!_validator.validateStatePayload(data)) return null;
    return _decodeBodyUnchecked(data);
  }

  @override
  Map<String, dynamic> encodeStateBody(CalendarSnapshot snapshot) {
    return _encodeBodyUnchecked(snapshot);
  }

  @override
  Map<String, dynamic> encodeBody(CalendarSnapshot snapshot) {
    final data = _encodeBody(snapshot, includeRuntimePoints: false);
    if (!_validator.validateSetPayload(data)) {
      throw const FormatException('Invalid schedule.set payload');
    }
    return data;
  }

  @override
  Map<String, dynamic> encodePatch({
    CalendarMode? mode,
    Map<CalendarMode, List<SchedulePoint>>? points,
    ScheduleRange? range,
  }) {
    final data = _encodePatchUnchecked(
      mode: mode,
      points: points,
      range: range,
    );
    if (!_validator.validatePatchPayload(data)) {
      throw const FormatException('Invalid schedule.patch payload');
    }
    return data;
  }

  /// Decodes a body without applying its runtime JSON schema first.
  ///
  /// This is intended for focused codec tests and already trusted local data.
  CalendarSnapshot? _decodeBodyUnchecked(Map<String, dynamic> data) {
    final modeRaw = data['mode'];
    if (modeRaw is! String) return null;

    final pointsRaw = data['points'];
    if (pointsRaw is! Map) return null;

    final lists = <CalendarMode, List<SchedulePoint>>{};
    for (final mode in CalendarMode.listModes) {
      lists[mode] = _sortedDedup(_decodePoints(pointsRaw[mode.id]));
    }

    final range = _decodeRange(pointsRaw['range']);
    if (range == null && pointsRaw.containsKey('range')) return null;

    return CalendarSnapshot(
      mode: _parseMode(modeRaw) ?? CalendarMode.off,
      range: range,
      currentPoint: decodePoint(data['current_point']),
      nextPoint: decodePoint(data['next_point']),
      lists: lists,
    );
  }

  /// Encodes state-shaped trusted local data, including runtime points.
  Map<String, dynamic> _encodeBodyUnchecked(CalendarSnapshot snapshot) {
    return _encodeBody(snapshot, includeRuntimePoints: true);
  }

  /// Encodes a patch without applying its runtime JSON Schema validation.
  Map<String, dynamic> _encodePatchUnchecked({
    CalendarMode? mode,
    Map<CalendarMode, List<SchedulePoint>>? points,
    ScheduleRange? range,
  }) {
    final data = <String, dynamic>{};
    if (mode != null) data['mode'] = mode.id;
    if ((points != null && points.isNotEmpty) || range != null) {
      data['points'] = _encodePoints(
        points ?? const {},
        range: range,
        includeAllListModes: false,
      );
    }
    return data;
  }

  SchedulePoint? decodePoint(dynamic raw);

  Map<String, dynamic> encodePoint(SchedulePoint point);

  Map<String, dynamic> _encodeBody(
    CalendarSnapshot snapshot, {
    required bool includeRuntimePoints,
  }) {
    final data = <String, dynamic>{
      'mode': snapshot.mode.id,
      'points': _encodePoints(
        snapshot.lists,
        range: snapshot.range,
        includeAllListModes: true,
      ),
    };

    if (includeRuntimePoints) {
      final currentPoint = snapshot.currentPoint;
      if (currentPoint != null) {
        data['current_point'] = encodePoint(currentPoint);
      }
      final nextPoint = snapshot.nextPoint;
      if (nextPoint != null) {
        data['next_point'] = encodePoint(nextPoint);
      }
    }
    return data;
  }

  List<SchedulePoint> _decodePoints(dynamic raw) {
    if (raw is! List) return const <SchedulePoint>[];

    final points = <SchedulePoint>[];
    for (final item in raw) {
      final point = decodePoint(item);
      if (point != null) points.add(point);
    }
    return points;
  }

  Map<String, dynamic> _encodePoints(
    Map<CalendarMode, List<SchedulePoint>> lists, {
    ScheduleRange? range,
    required bool includeAllListModes,
  }) {
    final data = <String, dynamic>{};
    if (includeAllListModes) {
      for (final mode in CalendarMode.listModes) {
        data[mode.id] = (lists[mode] ?? const <SchedulePoint>[])
            .map(encodePoint)
            .toList(growable: false);
      }
    } else {
      for (final entry in lists.entries) {
        data[entry.key.id] =
            entry.value.map(encodePoint).toList(growable: false);
      }
    }
    if (range != null) data['range'] = _encodeRange(range);
    return data;
  }
}
