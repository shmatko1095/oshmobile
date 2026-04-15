import 'package:shared_preferences/shared_preferences.dart';

class SelectedDeviceStorage {
  static const _prefix = 'selected_device:';

  final SharedPreferences _prefs;

  SelectedDeviceStorage(this._prefs);

  String _key(String userId) => '$_prefix$userId';

  String? loadSelectedDevice(String userId) {
    return _prefs.getString(_key(userId));
  }

  Future<void> saveSelectedDevice(String userId, String deviceId) {
    return _prefs.setString(_key(userId), deviceId);
  }

  Future<void> clearSelectedDevice(String userId) {
    return _prefs.remove(_key(userId));
  }
}
