part of 'device_facade.dart';

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
