import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';

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

  DeviceAboutApi get about;

  Future<void> dispose();
}

abstract interface class DeviceScheduleApi {
  CalendarSnapshot? get current;

  Stream<CalendarSnapshot> watch();

  Future<CalendarSnapshot> get({bool force = false});

  Future<void> commandSetMode(CalendarMode mode);

  void patchRange(ScheduleRange range);

  void patchList(CalendarMode mode, List<SchedulePoint> points);

  void patchPoint(int index, SchedulePoint point);

  void removePoint(int index);

  void addPoint([SchedulePoint? point, int stepMinutes = 15]);

  Future<void> save();

  void discardLocalChanges();
}

abstract interface class DeviceSettingsApi {
  SettingsSnapshot? get current;

  Stream<SettingsSnapshot> watch();

  Future<SettingsSnapshot> get({bool force = false});

  void patch(String path, Object? value);

  void patchAll(Map<String, Object?> patch);

  DeviceSettingsDisplayApi get display;

  DeviceSettingsUpdateApi get update;

  DeviceSettingsTimeApi get time;

  Future<void> save();

  void discardLocalChanges();
}

abstract interface class DeviceSettingsDisplayApi {
  void setActiveBrightness(int value);

  void setIdleBrightness(int value);

  void setIdleTime(int value);

  void setDimOnIdle(bool value);

  void setLanguage(String value);
}

abstract interface class DeviceSettingsUpdateApi {
  void setAutoUpdateEnabled(bool value);

  void setUpdateAtMidnight(bool value);

  void setCheckIntervalMin(int value);
}

abstract interface class DeviceSettingsTimeApi {
  void setAuto(bool value);

  void setTimeZone(int value);
}

abstract interface class DeviceSensorsApi {
  SensorsState? get current;

  Stream<SensorsState> watch();

  Future<SensorsState> get({bool force = false});

  Future<void> patch(SensorsPatch patch);

  Future<void> save(SensorsSetPayload payload);

  Future<void> rename({
    required String id,
    required String name,
  });

  Future<void> setReference({
    required String id,
  });

  Future<void> setTempCalibration({
    required String id,
    required double value,
  });

  Future<void> remove({
    required String id,
    bool? leave,
  });
}

abstract interface class DeviceTelemetryApi {
  Map<String, dynamic> get current;

  Stream<Map<String, dynamic>> watch();

  Future<Map<String, dynamic>> get({bool force = false});
}

abstract interface class DeviceAboutApi {
  Map<String, dynamic>? get current;

  Stream<Map<String, dynamic>> watch();

  Future<Map<String, dynamic>?> get({bool force = false});

  Future<void> stop();
}
