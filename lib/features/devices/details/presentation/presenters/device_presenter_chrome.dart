import 'package:flutter/material.dart';

class DevicePresenterChrome {
  const DevicePresenterChrome({
    required this.onOpenDrawer,
    required this.onOpenSettings,
    required this.activityIndicator,
  });

  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenSettings;
  final Widget activityIndicator;
}
