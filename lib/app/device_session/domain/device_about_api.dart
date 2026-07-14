part of 'device_facade.dart';

abstract interface class DeviceAboutApi {
  Map<String, dynamic>? get current;

  Stream<Map<String, dynamic>> watch();

  Future<Map<String, dynamic>?> get({bool force = false});

  Future<void> stop();
}
