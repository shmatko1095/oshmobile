import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_setpoint_history_reader.dart';

part 'device_about_api.dart';
part 'device_schedule_api.dart';
part 'device_sensors_api.dart';
part 'device_settings_api.dart';
part 'device_settings_display_api.dart';
part 'device_settings_time_api.dart';
part 'device_settings_update_api.dart';
part 'device_telemetry_api.dart';
part 'device_telemetry_history_api.dart';

abstract interface class DeviceFacade {
  DeviceSnapshot get current;

  SettingsUiSchema? get settingsUiSchema;

  Stream<DeviceSnapshot> watch();

  Future<void> start();

  Future<void> refreshAll({bool forceGet = false});

  DeviceScheduleApi get schedule;

  DeviceSettingsApi get settings;

  DeviceSensorsApi get sensors;

  DeviceTelemetryApi get telemetry;

  DeviceTelemetryHistoryApi get telemetryHistory;

  DeviceAboutApi get about;

  Future<void> dispose();
}
