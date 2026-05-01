class ConfigurationWidget {
  final String id;
  final List<String> controlIds;
  final Map<String, dynamic> options;

  const ConfigurationWidget({
    required this.id,
    required this.controlIds,
    this.options = const <String, dynamic>{},
  });

  factory ConfigurationWidget.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    return ConfigurationWidget(
      id: json['id']?.toString() ?? '',
      controlIds: (json['control_ids'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      options: optionsRaw is Map
          ? Map<String, dynamic>.unmodifiable(
              optionsRaw.map((key, value) => MapEntry(key.toString(), value)),
            )
          : const <String, dynamic>{},
    );
  }

  List<String> get modes => (options['modes'] as List? ?? const <dynamic>[])
      .map((item) => item.toString())
      .toList(growable: false);
}

class ConfigurationDomainContract {
  final String contractId;

  const ConfigurationDomainContract({
    required this.contractId,
  });

  factory ConfigurationDomainContract.fromJson(Map<String, dynamic> json) {
    return ConfigurationDomainContract(
      contractId: json['contract_id']?.toString() ?? '',
    );
  }
}

class ConfigurationSettingsGroup {
  final String id;
  final String title;
  final String? parentGroupId;
  final String presentation;
  final List<String> controlIds;

  const ConfigurationSettingsGroup({
    required this.id,
    required this.title,
    this.parentGroupId,
    this.presentation = 'inline',
    required this.controlIds,
  });

  factory ConfigurationSettingsGroup.fromJson(Map<String, dynamic> json) {
    return ConfigurationSettingsGroup(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      parentGroupId: json['parent_group_id']?.toString(),
      presentation: json['presentation']?.toString() ?? 'inline',
      controlIds: (json['control_ids'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class ConfigurationCollectionSource {
  final String id;
  final String domain;
  final String path;

  const ConfigurationCollectionSource({
    required this.id,
    required this.domain,
    required this.path,
  });

  factory ConfigurationCollectionSource.fromJson(Map<String, dynamic> json) {
    return ConfigurationCollectionSource(
      id: json['id']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
    );
  }
}

class ConfigurationCollection {
  final String id;
  final String key;
  final Map<String, ConfigurationCollectionSource> sources;
  final Map<String, String> fields;

  const ConfigurationCollection({
    required this.id,
    required this.key,
    required this.sources,
    required this.fields,
  });

  factory ConfigurationCollection.fromJson(Map<String, dynamic> json) {
    final sources = <String, ConfigurationCollectionSource>{};
    for (final raw in (json['sources'] as List? ?? const <dynamic>[])) {
      if (raw is! Map) continue;
      final source = ConfigurationCollectionSource.fromJson(
        raw.cast<String, dynamic>(),
      );
      if (source.id.isEmpty) continue;
      sources[source.id] = source;
    }

    final fields = <String, String>{};
    final fieldsRaw = json['fields'];
    if (fieldsRaw is Map) {
      fieldsRaw.forEach((key, value) {
        fields[key.toString()] = value?.toString() ?? '';
      });
    }

    return ConfigurationCollection(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      sources: Map.unmodifiable(sources),
      fields: Map.unmodifiable(fields),
    );
  }
}

class ControlSelector {
  final String field;
  final dynamic equals;
  final String fallback;

  const ControlSelector({
    required this.field,
    required this.equals,
    this.fallback = 'none',
  });

  factory ControlSelector.fromJson(Map<String, dynamic> json) {
    return ControlSelector(
      field: json['field']?.toString() ?? '',
      equals: json['equals'],
      fallback: json['fallback']?.toString() ?? 'none',
    );
  }
}

class ConfigurationReadBinding {
  final String kind;
  final String? domain;
  final String? path;
  final String? collection;
  final ControlSelector? select;
  final String? field;
  final String? validField;

  const ConfigurationReadBinding({
    required this.kind,
    this.domain,
    this.path,
    this.collection,
    this.select,
    this.field,
    this.validField,
  });

  factory ConfigurationReadBinding.fromJson(Map<String, dynamic> json) {
    final selectRaw = json['select'];
    return ConfigurationReadBinding(
      kind: json['kind']?.toString() ?? '',
      domain: json['domain']?.toString(),
      path: json['path']?.toString(),
      collection: json['collection']?.toString(),
      select: selectRaw is Map
          ? ControlSelector.fromJson(selectRaw.cast<String, dynamic>())
          : null,
      field: json['field']?.toString(),
      validField: json['valid_field']?.toString(),
    );
  }
}

class ConfigurationWriteBinding {
  final String kind;
  final String domain;
  final String? path;

  const ConfigurationWriteBinding({
    required this.kind,
    required this.domain,
    this.path,
  });

  factory ConfigurationWriteBinding.fromJson(Map<String, dynamic> json) {
    return ConfigurationWriteBinding(
      kind: json['kind']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      path: json['path']?.toString(),
    );
  }
}

class ConfigurationControlUi {
  final String? widget;
  final String? fieldType;
  final String? unit;
  final num? min;
  final num? max;
  final num? step;
  final List<String> enumValues;
  final Map<String, ConfigurationControlValueDisplay> enumDisplay;
  final Map<bool, ConfigurationControlBooleanDisplay> booleanDisplay;

  const ConfigurationControlUi({
    this.widget,
    this.fieldType,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.enumValues = const <String>[],
    this.enumDisplay = const <String, ConfigurationControlValueDisplay>{},
    this.booleanDisplay = const <bool, ConfigurationControlBooleanDisplay>{},
  });

  factory ConfigurationControlUi.fromJson(Map<String, dynamic> json) {
    final enumDisplay = <String, ConfigurationControlValueDisplay>{};
    final enumDisplayRaw = json['enum_display'];
    if (enumDisplayRaw is Map) {
      enumDisplayRaw.forEach((key, value) {
        if (value is! Map) return;
        enumDisplay[key.toString()] = ConfigurationControlValueDisplay.fromJson(
          value.cast<String, dynamic>(),
        );
      });
    }

    final booleanDisplay = <bool, ConfigurationControlBooleanDisplay>{};
    final booleanDisplayRaw = json['boolean_display'];
    if (booleanDisplayRaw is Map) {
      booleanDisplayRaw.forEach((key, value) {
        if (value is! Map) return;

        final normalizedKey = key.toString().trim().toLowerCase();
        if (normalizedKey == 'true') {
          booleanDisplay[true] = ConfigurationControlBooleanDisplay.fromJson(
            value.cast<String, dynamic>(),
          );
        } else if (normalizedKey == 'false') {
          booleanDisplay[false] = ConfigurationControlBooleanDisplay.fromJson(
            value.cast<String, dynamic>(),
          );
        }
      });
    }

    return ConfigurationControlUi(
      widget: json['widget']?.toString(),
      fieldType: json['field_type']?.toString(),
      unit: json['unit']?.toString(),
      min: json['min'] as num?,
      max: json['max'] as num?,
      step: json['step'] as num?,
      enumValues: (json['enum_values'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      enumDisplay: Map.unmodifiable(enumDisplay),
      booleanDisplay: Map.unmodifiable(booleanDisplay),
    );
  }
}

class ConfigurationControlValueDisplay {
  final String title;
  final String description;

  const ConfigurationControlValueDisplay({
    required this.title,
    required this.description,
  });

  factory ConfigurationControlValueDisplay.fromJson(Map<String, dynamic> json) {
    return ConfigurationControlValueDisplay(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class ConfigurationControlBooleanDisplay {
  final String description;

  const ConfigurationControlBooleanDisplay({
    required this.description,
  });

  factory ConfigurationControlBooleanDisplay.fromJson(
    Map<String, dynamic> json,
  ) {
    return ConfigurationControlBooleanDisplay(
      description: json['description']?.toString() ?? '',
    );
  }
}

class ConfigurationControl {
  final String id;
  final String title;
  final String description;
  final ConfigurationReadBinding? read;
  final ConfigurationWriteBinding? write;
  final ConfigurationControlUi? ui;

  const ConfigurationControl({
    required this.id,
    required this.title,
    required this.description,
    this.read,
    this.write,
    this.ui,
  });

  factory ConfigurationControl.fromJson(Map<String, dynamic> json) {
    final readRaw = json['read'];
    final writeRaw = json['write'];
    final uiRaw = json['ui'];

    return ConfigurationControl(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      read: readRaw is Map
          ? ConfigurationReadBinding.fromJson(readRaw.cast<String, dynamic>())
          : null,
      write: writeRaw is Map
          ? ConfigurationWriteBinding.fromJson(
              writeRaw.cast<String, dynamic>(),
            )
          : null,
      ui: uiRaw is Map
          ? ConfigurationControlUi.fromJson(uiRaw.cast<String, dynamic>())
          : null,
    );
  }
}

class OshmobileConfiguration {
  final String layout;
  final Map<String, ConfigurationDomainContract> domains;
  final Map<String, ConfigurationWidget> widgets;
  final Map<String, ConfigurationSettingsGroup> settingsGroups;
  final Map<String, ConfigurationCollection> collections;
  final Map<String, ConfigurationControl> controls;

  const OshmobileConfiguration({
    required this.layout,
    required this.domains,
    required this.widgets,
    required this.settingsGroups,
    required this.collections,
    required this.controls,
  });

  factory OshmobileConfiguration.fromJson(Map<String, dynamic> json) {
    final rawDomains = json['domains'];
    final domains = <String, ConfigurationDomainContract>{};
    if (rawDomains is Map) {
      rawDomains.forEach((key, value) {
        if (value is! Map) return;
        domains[key.toString()] = ConfigurationDomainContract.fromJson(
          value.cast<String, dynamic>(),
        );
      });
    }

    return OshmobileConfiguration(
      layout: json['layout']?.toString() ?? '',
      domains: Map.unmodifiable(domains),
      widgets: _indexedById(
        json['widgets'],
        (item) => ConfigurationWidget.fromJson(item),
      ),
      settingsGroups: _indexedById(
        json['settings_groups'],
        (item) => ConfigurationSettingsGroup.fromJson(item),
      ),
      collections: _indexedById(
        json['collections'],
        (item) => ConfigurationCollection.fromJson(item),
      ),
      controls: _indexedById(
        json['controls'],
        (item) => ConfigurationControl.fromJson(item),
      ),
    );
  }
}

class ModelConfiguration {
  final int schemaVersion;
  final OshmobileConfiguration oshmobile;

  const ModelConfiguration({
    required this.schemaVersion,
    required this.oshmobile,
  });

  factory ModelConfiguration.fromJson(Map<String, dynamic> json) {
    final integrationsRaw = json['integrations'];
    final integrations = integrationsRaw is Map
        ? integrationsRaw.cast<String, dynamic>()
        : const <String, dynamic>{};
    final oshmobileRaw = integrations['oshmobile'];

    return ModelConfiguration(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 0,
      oshmobile: OshmobileConfiguration.fromJson(
        oshmobileRaw is Map ? oshmobileRaw.cast<String, dynamic>() : const {},
      ),
    );
  }
}

Map<String, T> _indexedById<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) mapper,
) {
  final items = <String, T>{};
  if (raw is! List) {
    return items;
  }

  for (final item in raw) {
    if (item is! Map) continue;
    final json = item.cast<String, dynamic>();
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    items[id] = mapper(json);
  }
  return Map.unmodifiable(items);
}
