import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class BlePermissionService {
  Future<bool> ensureBlePermissions() async {
    if (Platform.isAndroid) {
      return _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return _requestIosPermissions();
    } else {
      return false;
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    final statuses = await permissions.request();

    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      await openAppSettings();
      return false;
    }

    return statuses.values.every((s) => s.isGranted);
  }

  Future<bool> _requestIosPermissions() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.bluetooth,
    ];

    final statuses = await permissions.request();

    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      await openAppSettings();
      return false;
    }

    return statuses.values.every((s) => s.isGranted);
  }
}
