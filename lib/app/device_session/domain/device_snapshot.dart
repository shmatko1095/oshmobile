import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/devices/details/presentation/models/osh_config.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';

enum DeviceSliceStatus {
  idle,
  loading,
  ready,
  saving,
  error,
}

class DeviceSlice<T> {
  final DeviceSliceStatus status;
  final T? data;
  final String? error;
  final bool dirty;

  const DeviceSlice({
    required this.status,
    this.data,
    this.error,
    this.dirty = false,
  });

  const DeviceSlice.idle({
    this.data,
    this.error,
    this.dirty = false,
  }) : status = DeviceSliceStatus.idle;

  const DeviceSlice.loading({
    this.data,
    this.error,
    this.dirty = false,
  }) : status = DeviceSliceStatus.loading;

  const DeviceSlice.ready({
    required this.data,
    this.error,
    this.dirty = false,
  }) : status = DeviceSliceStatus.ready;

  const DeviceSlice.saving({
    required this.data,
    this.error,
    this.dirty = false,
  }) : status = DeviceSliceStatus.saving;

  const DeviceSlice.error({
    this.data,
    required this.error,
    this.dirty = false,
  }) : status = DeviceSliceStatus.error;
}

class DeviceSnapshot {
  final Device device;
  final DeviceSlice<DeviceConfig> details;
  final bool mqttConnected;
  final bool mqttBusy;
  final String? commError;

  final DeviceSlice<Map<String, dynamic>> telemetry;
  final DeviceSlice<CalendarSnapshot> schedule;
  final DeviceSlice<SettingsSnapshot> settings;
  final SettingsUiSchema? settingsUiSchema;
  final DeviceSlice<Map<String, dynamic>> about;

  final DateTime updatedAt;

  const DeviceSnapshot({
    required this.device,
    required this.details,
    required this.mqttConnected,
    required this.mqttBusy,
    required this.commError,
    required this.telemetry,
    required this.schedule,
    required this.settings,
    required this.settingsUiSchema,
    required this.about,
    required this.updatedAt,
  });

  factory DeviceSnapshot.initial({
    required Device device,
  }) {
    return DeviceSnapshot(
      device: device,
      details: const DeviceSlice<DeviceConfig>.idle(),
      mqttConnected: false,
      mqttBusy: false,
      commError: null,
      telemetry: const DeviceSlice<Map<String, dynamic>>.idle(data: {}),
      schedule: const DeviceSlice<CalendarSnapshot>.idle(),
      settings: const DeviceSlice<SettingsSnapshot>.idle(),
      settingsUiSchema: null,
      about: const DeviceSlice<Map<String, dynamic>>.idle(),
      updatedAt: DateTime.now(),
    );
  }

  DeviceSnapshot copyWith({
    Device? device,
    DeviceSlice<DeviceConfig>? details,
    bool? mqttConnected,
    bool? mqttBusy,
    String? commError,
    bool clearCommError = false,
    DeviceSlice<Map<String, dynamic>>? telemetry,
    DeviceSlice<CalendarSnapshot>? schedule,
    DeviceSlice<SettingsSnapshot>? settings,
    SettingsUiSchema? settingsUiSchema,
    bool clearSettingsUiSchema = false,
    DeviceSlice<Map<String, dynamic>>? about,
    DateTime? updatedAt,
  }) {
    return DeviceSnapshot(
      device: device ?? this.device,
      details: details ?? this.details,
      mqttConnected: mqttConnected ?? this.mqttConnected,
      mqttBusy: mqttBusy ?? this.mqttBusy,
      commError: clearCommError ? null : (commError ?? this.commError),
      telemetry: telemetry ?? this.telemetry,
      schedule: schedule ?? this.schedule,
      settings: settings ?? this.settings,
      settingsUiSchema: clearSettingsUiSchema
          ? null
          : (settingsUiSchema ?? this.settingsUiSchema),
      about: about ?? this.about,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
