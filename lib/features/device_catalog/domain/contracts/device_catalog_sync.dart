abstract interface class DeviceCatalogSync {
  Future<void> refresh();

  void onDeviceRemoved(String deviceId);
}
