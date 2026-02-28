class ModelProfileBootstrap {
  final bool contractsRequired;
  final bool legacyFallbackAllowed;

  const ModelProfileBootstrap({
    required this.contractsRequired,
    required this.legacyFallbackAllowed,
  });

  factory ModelProfileBootstrap.fromJson(Map<String, dynamic> json) {
    return ModelProfileBootstrap(
      contractsRequired: json['contracts_required'] == true,
      legacyFallbackAllowed: json['legacy_fallback_allowed'] == true,
    );
  }
}

class ModelProfileDomainPolicy {
  final bool required;
  final String? notes;

  const ModelProfileDomainPolicy({
    required this.required,
    this.notes,
  });

  factory ModelProfileDomainPolicy.fromJson(Map<String, dynamic> json) {
    return ModelProfileDomainPolicy(
      required: json['required'] == true,
      notes: json['notes']?.toString(),
    );
  }
}

class ModelProfileWidget {
  final bool enabled;
  final List<String> controlIds;
  final String? description;

  const ModelProfileWidget({
    required this.enabled,
    required this.controlIds,
    this.description,
  });

  factory ModelProfileWidget.fromJson(Map<String, dynamic> json) {
    return ModelProfileWidget(
      enabled: json['enabled'] == true,
      controlIds: (json['control_ids'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      description: json['description']?.toString(),
    );
  }
}

class ModelProfileControl {
  final bool enabled;
  final List<String> widgetIds;
  final String? settingsGroup;
  final int? order;
  final String? notes;

  const ModelProfileControl({
    required this.enabled,
    this.widgetIds = const <String>[],
    this.settingsGroup,
    this.order,
    this.notes,
  });

  factory ModelProfileControl.fromJson(Map<String, dynamic> json) {
    return ModelProfileControl(
      enabled: json['enabled'] == true,
      widgetIds: (json['widget_ids'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      settingsGroup: json['settings_group']?.toString(),
      order: json['order'] is num ? (json['order'] as num).toInt() : null,
      notes: json['notes']?.toString(),
    );
  }
}

class ModelProfileSettingsGroup {
  final String id;
  final String title;
  final List<String> order;

  const ModelProfileSettingsGroup({
    required this.id,
    required this.title,
    required this.order,
  });

  factory ModelProfileSettingsGroup.fromJson(Map<String, dynamic> json) {
    return ModelProfileSettingsGroup(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      order: (json['order'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class ModelProfileOsh {
  final ModelProfileBootstrap bootstrap;
  final Map<String, ModelProfileDomainPolicy> domains;
  final Map<String, ModelProfileWidget> widgets;
  final Map<String, ModelProfileControl> controls;
  final List<ModelProfileSettingsGroup> settingsGroups;
  final List<String> scheduleModes;

  const ModelProfileOsh({
    required this.bootstrap,
    required this.domains,
    required this.widgets,
    required this.controls,
    required this.settingsGroups,
    required this.scheduleModes,
  });

  factory ModelProfileOsh.fromJson(Map<String, dynamic> json) {
    final bootstrapRaw = json['bootstrap'];
    final domainsRaw = json['domains'];
    final widgets = <String, ModelProfileWidget>{};
    final controls = <String, ModelProfileControl>{};
    final domains = <String, ModelProfileDomainPolicy>{};

    if (domainsRaw is Map) {
      domainsRaw.forEach((key, value) {
        if (value is! Map) return;
        domains[key.toString()] =
            ModelProfileDomainPolicy.fromJson(value.cast<String, dynamic>());
      });
    }

    final widgetsRaw = json['widgets'];
    if (widgetsRaw is Map) {
      widgetsRaw.forEach((key, value) {
        if (value is! Map) return;
        widgets[key.toString()] =
            ModelProfileWidget.fromJson(value.cast<String, dynamic>());
      });
    }

    final controlsRaw = json['controls'];
    if (controlsRaw is Map) {
      controlsRaw.forEach((key, value) {
        if (value is! Map) return;
        controls[key.toString()] =
            ModelProfileControl.fromJson(value.cast<String, dynamic>());
      });
    }

    return ModelProfileOsh(
      bootstrap: ModelProfileBootstrap.fromJson(
        bootstrapRaw is Map ? bootstrapRaw.cast<String, dynamic>() : const {},
      ),
      domains: Map.unmodifiable(domains),
      widgets: Map.unmodifiable(widgets),
      controls: Map.unmodifiable(controls),
      settingsGroups: (json['settings_groups'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) =>
              ModelProfileSettingsGroup.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
      scheduleModes: (json['schedule_modes'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  ModelProfileDomainPolicy domainPolicy(String domain) {
    return domains[domain] ??
        const ModelProfileDomainPolicy(
          required: false,
        );
  }
}

class ModelProfile {
  final int profileSchemaVersion;
  final String modelId;
  final String modelName;
  final String displayName;
  final String profileVersion;
  final ModelProfileOsh osh;

  const ModelProfile({
    required this.profileSchemaVersion,
    required this.modelId,
    required this.modelName,
    required this.displayName,
    required this.profileVersion,
    required this.osh,
  });

  factory ModelProfile.fromJson(Map<String, dynamic> json) {
    final integrationsRaw = json['integrations'];
    final oshRaw = integrationsRaw is Map ? integrationsRaw['osh'] : null;

    return ModelProfile(
      profileSchemaVersion:
          (json['profile_schema_version'] as num?)?.toInt() ?? 0,
      modelId: json['model_id']?.toString() ?? '',
      modelName: json['model_name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      profileVersion: json['profile_version']?.toString() ?? '',
      osh: ModelProfileOsh.fromJson(
        oshRaw is Map ? oshRaw.cast<String, dynamic>() : const {},
      ),
    );
  }
}
