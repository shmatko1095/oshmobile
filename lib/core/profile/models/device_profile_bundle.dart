import 'package:oshmobile/core/profile/models/control_binding.dart';
import 'package:oshmobile/core/profile/models/model_profile.dart';

class ControlCatalogEntry {
  final String title;
  final String access;
  final String? description;
  final String? valueSchemaRef;
  final String? unit;

  const ControlCatalogEntry({
    required this.title,
    required this.access,
    this.description,
    this.valueSchemaRef,
    this.unit,
  });

  factory ControlCatalogEntry.fromJson(Map<String, dynamic> json) {
    final presentationRaw = json['presentation'];
    final unit = presentationRaw is Map
        ? presentationRaw['unit']?.toString()
        : json['unit']?.toString();
    final valueSchemaRef = json['valueSchemaRef']?.toString();

    return ControlCatalogEntry(
      title: json['title']?.toString() ?? '',
      access: json['access']?.toString() ?? 'read',
      description: json['description']?.toString(),
      valueSchemaRef: valueSchemaRef,
      unit: unit,
    );
  }
}

class ActionCatalogEntry {
  final String title;
  final String? description;
  final String? feature;
  final String? inputSchemaRef;

  const ActionCatalogEntry({
    required this.title,
    this.description,
    this.feature,
    this.inputSchemaRef,
  });

  factory ActionCatalogEntry.fromJson(Map<String, dynamic> json) {
    return ActionCatalogEntry(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      feature: json['feature']?.toString(),
      inputSchemaRef: json['inputSchemaRef']?.toString(),
    );
  }
}

class DeviceProfileBundle {
  final int bundleSchemaVersion;
  final String serial;
  final String modelId;
  final String modelName;
  final String profileVersion;
  final Set<String> negotiatedSchemas;
  final Set<String> readableDomains;
  final Set<String> patchableDomains;
  final Set<String> settableDomains;
  final Map<String, Set<String>> negotiatedFeaturesByDomain;
  final ModelProfile modelProfile;
  final Map<String, ControlCatalogEntry> controlCatalog;
  final Map<String, ActionCatalogEntry> actionCatalog;
  final Map<String, ControlBinding> bindings;
  final Map<String, ActionBinding> actionBindings;

  const DeviceProfileBundle({
    required this.bundleSchemaVersion,
    required this.serial,
    required this.modelId,
    required this.modelName,
    required this.profileVersion,
    required this.negotiatedSchemas,
    this.readableDomains = const <String>{},
    this.patchableDomains = const <String>{},
    this.settableDomains = const <String>{},
    this.negotiatedFeaturesByDomain = const <String, Set<String>>{},
    required this.modelProfile,
    required this.controlCatalog,
    this.actionCatalog = const <String, ActionCatalogEntry>{},
    required this.bindings,
    this.actionBindings = const <String, ActionBinding>{},
  });

  factory DeviceProfileBundle.fromJson(Map<String, dynamic> json) {
    final controlCatalog = <String, ControlCatalogEntry>{};
    final controlMapRaw =
        _catalogEntries(json['control_catalog'], key: 'controls');
    if (controlMapRaw != null) {
      controlMapRaw.forEach((key, value) {
        if (value is! Map) return;
        controlCatalog[key.toString()] =
            ControlCatalogEntry.fromJson(value.cast<String, dynamic>());
      });
    }

    final actionCatalog = <String, ActionCatalogEntry>{};
    final actionMapRaw =
        _catalogEntries(json['action_catalog'], key: 'actions');
    if (actionMapRaw != null) {
      actionMapRaw.forEach((key, value) {
        if (value is! Map) return;
        actionCatalog[key.toString()] =
            ActionCatalogEntry.fromJson(value.cast<String, dynamic>());
      });
    }

    final bindings = <String, ControlBinding>{};
    final actionBindings = <String, ActionBinding>{};
    final bindingsRaw = json['bindings'];
    if (bindingsRaw is Map) {
      final legacyControlsRaw = bindingsRaw['controls'];
      if (legacyControlsRaw is Map) {
        legacyControlsRaw.forEach((key, value) {
          if (value is! Map) return;
          bindings[key.toString()] =
              ControlBinding.fromJson(value.cast<String, dynamic>());
        });
      } else {
        bindingsRaw.forEach((_, domainCatalogRaw) {
          if (domainCatalogRaw is! Map) return;
          final domainCatalog = domainCatalogRaw.cast<String, dynamic>();
          final domain = domainCatalog['domain']?.toString();
          final schema = domainCatalog['schema']?.toString();

          final controlsRaw = domainCatalog['controls'];
          if (controlsRaw is Map) {
            controlsRaw.forEach((key, value) {
              if (value is! Map) return;
              bindings[key.toString()] = ControlBinding.fromJson(
                _normalizeBinding(
                  value.cast<String, dynamic>(),
                  domain: domain,
                  schema: schema,
                ),
              );
            });
          }

          final actionsRaw = domainCatalog['actions'];
          if (actionsRaw is Map) {
            actionsRaw.forEach((key, value) {
              if (value is! Map) return;
              actionBindings[key.toString()] = ActionBinding.fromJson(
                _normalizeBinding(
                  value.cast<String, dynamic>(),
                  domain: domain,
                  schema: schema,
                ),
              );
            });
          }
        });
      }
    }

    return DeviceProfileBundle(
      bundleSchemaVersion:
          (json['bundle_schema_version'] as num?)?.toInt() ?? 0,
      serial: json['serial']?.toString() ?? '',
      modelId: json['model_id']?.toString() ?? '',
      modelName: json['model_name']?.toString() ??
          (((json['model_profile'] as Map? ?? const {})['model_name'])
                  ?.toString() ??
              ''),
      profileVersion: json['profile_version']?.toString() ?? '',
      negotiatedSchemas:
          (json['negotiated_schemas'] as List? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toSet(),
      modelProfile: ModelProfile.fromJson(
        (json['model_profile'] as Map? ?? const {}).cast<String, dynamic>(),
      ),
      controlCatalog: Map.unmodifiable(controlCatalog),
      actionCatalog: Map.unmodifiable(actionCatalog),
      bindings: Map.unmodifiable(bindings),
      actionBindings: Map.unmodifiable(actionBindings),
    );
  }

  DeviceProfileBundle copyWith({
    String? serial,
    String? modelId,
    String? modelName,
    Set<String>? negotiatedSchemas,
    Set<String>? readableDomains,
    Set<String>? patchableDomains,
    Set<String>? settableDomains,
    Map<String, Set<String>>? negotiatedFeaturesByDomain,
    ModelProfile? modelProfile,
  }) {
    return DeviceProfileBundle(
      bundleSchemaVersion: bundleSchemaVersion,
      serial: serial ?? this.serial,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      profileVersion: profileVersion,
      negotiatedSchemas: negotiatedSchemas ?? this.negotiatedSchemas,
      readableDomains: readableDomains ?? this.readableDomains,
      patchableDomains: patchableDomains ?? this.patchableDomains,
      settableDomains: settableDomains ?? this.settableDomains,
      negotiatedFeaturesByDomain:
          negotiatedFeaturesByDomain ?? this.negotiatedFeaturesByDomain,
      modelProfile: modelProfile ?? this.modelProfile,
      controlCatalog: controlCatalog,
      actionCatalog: actionCatalog,
      bindings: bindings,
      actionBindings: actionBindings,
    );
  }

  bool isWidgetEnabled(String widgetId) {
    return modelProfile.osh.widgets[widgetId]?.enabled == true;
  }

  List<String> widgetControlIds(String widgetId) {
    return modelProfile.osh.widgets[widgetId]?.controlIds ?? const <String>[];
  }

  bool isControlEnabled(String controlId) {
    return modelProfile.osh.controls[controlId]?.enabled == true;
  }

  bool canRenderWidget(String widgetId) {
    final widget = modelProfile.osh.widgets[widgetId];
    if (widget == null || !widget.enabled) return false;
    return widget.controlIds.every(isControlEnabled);
  }

  bool supportsFeature(String domain, String feature) {
    return negotiatedFeaturesByDomain[domain]?.contains(feature) == true;
  }

  bool canReadDomain(String domain) => readableDomains.contains(domain);

  bool canPatchDomain(String domain) => patchableDomains.contains(domain);

  bool canSetDomain(String domain) => settableDomains.contains(domain);

  static Map? _catalogEntries(dynamic raw, {required String key}) {
    if (raw is! Map) return null;
    final nested = raw[key];
    if (nested is Map) return nested;
    return raw;
  }

  // Normalize domain-scoped binding catalogs into the flattened structure the app uses.
  static Map<String, dynamic> _normalizeBinding(
    Map<String, dynamic> raw, {
    required String? domain,
    required String? schema,
  }) {
    Map<String, dynamic> normalizeAction(Map<String, dynamic> action) {
      final next = Map<String, dynamic>.from(action);

      if (domain != null && !next.containsKey('domain')) {
        next['domain'] = domain;
      }
      if (schema != null && !next.containsKey('schema')) {
        next['schema'] = schema;
      }

      final requires = <String>[
        ...(next['requires'] as List? ?? const <dynamic>[])
            .map((item) => item.toString()),
      ];
      if (schema != null && schema.isNotEmpty && !requires.contains(schema)) {
        requires.add(schema);
      }
      if (requires.isNotEmpty) {
        next['requires'] = List<String>.unmodifiable(requires);
      }

      return next;
    }

    final next = Map<String, dynamic>.from(raw);
    final readRaw = next['read'];
    final writeRaw = next['write'];
    if (readRaw is Map) {
      next['read'] = normalizeAction(readRaw.cast<String, dynamic>());
    }
    if (writeRaw is Map) {
      next['write'] = normalizeAction(writeRaw.cast<String, dynamic>());
    }
    return next;
  }
}
