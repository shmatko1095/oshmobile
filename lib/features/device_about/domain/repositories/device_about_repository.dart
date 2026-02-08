abstract class DeviceAboutRepository {
  /// Stream of raw device state payloads.
  Stream<Map<String, dynamic>> watchState();
}
