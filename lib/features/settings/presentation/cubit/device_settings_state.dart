part of 'device_settings_cubit.dart';

/// Latest-wins "queued intents" requested while an operation is in-flight.
/// For settings we only need "saveAll requested again".
class SettingsQueued {
  final bool saveAll;

  const SettingsQueued({this.saveAll = false});

  bool get isEmpty => !saveAll;

  SettingsQueued withSaveAll() => const SettingsQueued(saveAll: true);

  SettingsQueued clearSaveAll() => const SettingsQueued(saveAll: false);

  SettingsQueued clear() => const SettingsQueued(saveAll: false);
}

sealed class DeviceSettingsState {
  const DeviceSettingsState();

  bool get isReady => this is DeviceSettingsReady;
  bool get dirty => false;
  bool get saving => false;
}

class DeviceSettingsLoading extends DeviceSettingsState {
  const DeviceSettingsLoading();
}

class DeviceSettingsError extends DeviceSettingsState {
  final String message;

  const DeviceSettingsError(this.message);
}

class DeviceSettingsReady extends DeviceSettingsState {
  /// Confirmed snapshot from the device (reported/fetched).
  final SettingsSnapshot base;

  /// Local UI overrides (dot-path -> value).
  /// If a value is `null` we interpret it as removal (same rule as copyWithValue).
  final Map<String, Object?> overrides;

  @override
  final bool saving;

  /// One-shot UI message (snackbar).
  final String? flash;

  /// Latest-wins queued intents while saving.
  final SettingsQueued queued;

  const DeviceSettingsReady({
    required this.base,
    this.overrides = const {},
    this.saving = false,
    this.flash,
    this.queued = const SettingsQueued(),
  });

  /// Draft snapshot shown to UI: base + overrides.
  SettingsSnapshot get snapshot {
    var s = base;
    overrides.forEach((path, value) {
      s = s.copyWithValue(path, value);
    });
    return s;
  }

  @override
  bool get dirty => overrides.isNotEmpty;

  DeviceSettingsReady copyWith({
    SettingsSnapshot? base,
    Map<String, Object?>? overrides,
    bool? saving,
    String? flash, // pass null to clear
    SettingsQueued? queued,
  }) {
    return DeviceSettingsReady(
      base: base ?? this.base,
      overrides: overrides ?? this.overrides,
      saving: saving ?? this.saving,
      flash: flash,
      queued: queued ?? this.queued,
    );
  }
}
