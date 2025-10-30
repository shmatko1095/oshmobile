abstract class DeviceControlRepository {
  /// Enable real-time streaming on device (e.g., 1 Hz) while user watches the page.
  Future<void> enableRtStreaming(String deviceId, {required Duration interval});

  /// Disable real-time streaming / revert to default (e.g., 5 minutes).
  Future<void> disableRtStreaming(String deviceId);
}
