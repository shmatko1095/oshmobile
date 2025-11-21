import 'package:shared_preferences/shared_preferences.dart';

class SelectedDeviceStorage {
  final SharedPreferences _prefs;

  SelectedDeviceStorage(this._prefs);

  String _key(String userUuid) => 'selected_device_$userUuid';

  /// Save selected device id for specific user
  Future<void> saveSelectedDevice(String userUuid, String deviceId) async {
    await _prefs.setString(_key(userUuid), deviceId);
  }

  /// Load selected device id for specific user
  String? loadSelectedDevice(String userUuid) {
    return _prefs.getString(_key(userUuid));
  }

  /// Clear stored selected device for specific user
  Future<void> clearSelectedDevice(String userUuid) async {
    await _prefs.remove(_key(userUuid));
  }
}
