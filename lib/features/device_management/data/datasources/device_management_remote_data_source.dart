abstract interface class DeviceManagementRemoteDataSource {
  Future<void> renameDevice({
    required String serial,
    required String alias,
    required String description,
  });

  Future<void> removeDevice({
    required String serial,
  });
}
