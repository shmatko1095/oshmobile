abstract interface class OshRemoteDataSource {
  Future<void> assignDevice({
    required String uuid,
    required String sn,
    required String sc,
  });

  Future<void> unassignDevice({
    required String uuid,
    required String sn,
  });

  Future<void> getDeviceList({
    required String uuid,
  });
}
