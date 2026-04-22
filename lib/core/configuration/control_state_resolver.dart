import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/utils/schedule_point_resolver.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';

class ControlStateResolver {
  const ControlStateResolver();

  Map<String, dynamic> resolveAll({
    required ControlRegistry registry,
    required Iterable<String> controlIds,
    TelemetryState? telemetry,
    SensorsState? sensors,
    CalendarSnapshot? schedule,
    SettingsSnapshot? settings,
    Map<String, dynamic>? deviceState,
    Map<String, dynamic>? diagState,
  }) {
    final out = <String, dynamic>{};
    final collections = <String, List<Map<String, dynamic>>>{};

    for (final controlId in controlIds) {
      if (!registry.canRead(controlId)) continue;
      final binding = registry.readBinding(controlId);
      if (binding == null) continue;

      final value = _resolveBinding(
        binding,
        registry: registry,
        collections: collections,
        telemetry: telemetry,
        sensors: sensors,
        schedule: schedule,
        settings: settings,
        deviceState: deviceState,
        diagState: diagState,
      );
      if (value != null) {
        out[controlId] = value;
      }
    }

    return out;
  }

  dynamic _resolveBinding(
    ConfigurationReadBinding binding, {
    required ControlRegistry registry,
    required Map<String, List<Map<String, dynamic>>> collections,
    required TelemetryState? telemetry,
    required SensorsState? sensors,
    required CalendarSnapshot? schedule,
    required SettingsSnapshot? settings,
    required Map<String, dynamic>? deviceState,
    required Map<String, dynamic>? diagState,
  }) {
    switch (binding.kind) {
      case 'domain_path':
        final snapshot = _snapshotForDomain(
          binding.domain,
          telemetry: telemetry,
          sensors: sensors,
          schedule: schedule,
          settings: settings,
          deviceState: deviceState,
          diagState: diagState,
        );
        return _readPath(snapshot, binding.path);

      case 'collection':
        final collectionId = binding.collection;
        if (collectionId == null || collectionId.isEmpty) return null;
        return _resolveCollection(
          collectionId,
          registry: registry,
          collections: collections,
          telemetry: telemetry,
          sensors: sensors,
          schedule: schedule,
          settings: settings,
          deviceState: deviceState,
          diagState: diagState,
        );

      case 'collection_item_field':
        final collectionId = binding.collection;
        final field = binding.field;
        if (collectionId == null ||
            collectionId.isEmpty ||
            field == null ||
            field.isEmpty) {
          return null;
        }
        final items = _resolveCollection(
          collectionId,
          registry: registry,
          collections: collections,
          telemetry: telemetry,
          sensors: sensors,
          schedule: schedule,
          settings: settings,
          deviceState: deviceState,
          diagState: diagState,
        );
        final selected = _selectCollectionItem(items, binding.select);
        if (selected == null) return null;
        final validField = binding.validField;
        if (validField != null && selected[validField] != true) {
          return null;
        }
        return selected[field];

      case 'schedule_current_target':
        if (schedule == null) return null;
        return (schedule.currentPoint ?? resolveCurrentPoint(schedule))?.temp;

      case 'schedule_next_target':
        if (schedule == null) return null;
        final point = schedule.nextPoint ?? resolveNextPoint(schedule);
        return _nextTargetFromPoint(point);
    }

    return null;
  }

  List<Map<String, dynamic>> _resolveCollection(
    String collectionId, {
    required ControlRegistry registry,
    required Map<String, List<Map<String, dynamic>>> collections,
    required TelemetryState? telemetry,
    required SensorsState? sensors,
    required CalendarSnapshot? schedule,
    required SettingsSnapshot? settings,
    required Map<String, dynamic>? deviceState,
    required Map<String, dynamic>? diagState,
  }) {
    final cached = collections[collectionId];
    if (cached != null) return cached;

    final collection =
        registry.bundle.configuration.oshmobile.collections[collectionId];
    if (collection == null) {
      return const <Map<String, dynamic>>[];
    }

    final keyOrder = <String>[];
    final rowsByKey = <String, Map<String, Map<String, dynamic>>>{};
    for (final source in collection.sources.values) {
      final snapshot = _snapshotForDomain(
        source.domain,
        telemetry: telemetry,
        sensors: sensors,
        schedule: schedule,
        settings: settings,
        deviceState: deviceState,
        diagState: diagState,
      );
      final rawItems = _readPath(snapshot, source.path);
      if (rawItems is! List) continue;

      for (final item in rawItems) {
        final normalized = _normalizeMap(item);
        if (normalized == null) continue;
        final keyValue = normalized[collection.key];
        if (keyValue == null) continue;
        final key = keyValue.toString();
        if (!rowsByKey.containsKey(key)) {
          keyOrder.add(key);
          rowsByKey[key] = <String, Map<String, dynamic>>{};
        }
        rowsByKey[key]![source.id] = normalized;
      }
    }

    final resolved = <Map<String, dynamic>>[];
    for (final key in keyOrder) {
      final sourceRows = rowsByKey[key];
      if (sourceRows == null) continue;
      final row = <String, dynamic>{};
      collection.fields.forEach((outField, mapping) {
        final parts = mapping.split('.');
        if (parts.length < 2) return;
        final sourceId = parts.first;
        final sourceRow = sourceRows[sourceId];
        if (sourceRow == null) return;
        final value = _readPath(
          sourceRow,
          parts.skip(1).join('.'),
        );
        if (value != null) {
          row[outField] = value;
        }
      });
      if (row.isNotEmpty) {
        resolved.add(Map<String, dynamic>.unmodifiable(row));
      }
    }

    final frozen = List<Map<String, dynamic>>.unmodifiable(resolved);
    collections[collectionId] = frozen;
    return frozen;
  }

  Map<String, dynamic>? _selectCollectionItem(
    List<Map<String, dynamic>> items,
    ControlSelector? selector,
  ) {
    if (items.isEmpty) return null;
    if (selector == null || selector.field.isEmpty) {
      return items.first;
    }

    for (final item in items) {
      if (item[selector.field] == selector.equals) {
        return item;
      }
    }

    if (selector.fallback == 'first') {
      return items.first;
    }
    return null;
  }

  Map<String, dynamic>? _snapshotForDomain(
    String? domain, {
    required TelemetryState? telemetry,
    required SensorsState? sensors,
    required CalendarSnapshot? schedule,
    required SettingsSnapshot? settings,
    required Map<String, dynamic>? deviceState,
    required Map<String, dynamic>? diagState,
  }) {
    switch (domain) {
      case 'telemetry':
        return telemetry?.toJson();
      case 'sensors':
        return sensors?.toJson();
      case 'schedule':
        return schedule == null
            ? null
            : ScheduleJsonRpcCodec.encodeBodyUnchecked(schedule);
      case 'settings':
        return settings?.toJson();
      case 'device':
        return deviceState;
      case 'diag':
        return diagState;
      default:
        return null;
    }
  }

  Map<String, dynamic>? _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  dynamic _readPath(dynamic root, String? path) {
    if (root == null || path == null || path.isEmpty) {
      return root;
    }

    dynamic current = root;
    for (final part in path.split('.')) {
      if (current is Map<String, dynamic>) {
        current = current[part];
        continue;
      }
      if (current is Map) {
        current = current[part];
        continue;
      }
      return null;
    }
    return current;
  }

  Map<String, dynamic>? _nextTargetFromPoint(SchedulePoint? point) {
    if (point == null) return null;
    return <String, dynamic>{
      'temp': point.temp,
      'hour': point.time.hour,
      'minute': point.time.minute,
    };
  }
}
