import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provides a stable identifier for this app installation on this device.
/// The ID is generated once and then stored in SharedPreferences.
class AppDeviceIdProvider {
  static const _storageKey = 'osh_app_device_id';

  final Uuid _uuid;

  AppDeviceIdProvider({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  /// Returns a stable device id. Generates and stores a new one on first call.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await prefs.setString(_storageKey, newId);
    return newId;
  }
}
