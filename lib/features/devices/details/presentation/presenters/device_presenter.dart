import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/unknown_config_presenter.dart';

abstract class DevicePresenter {
  Widget build(
    BuildContext context,
    Device device,
    DeviceConfigurationBundle bundle,
  );
}

class DevicePresenterRegistry {
  final Map<String, DevicePresenter> _map;

  const DevicePresenterRegistry(this._map);

  DevicePresenter resolve(String layout) =>
      _map[layout] ?? const UnknownConfigPresenter();
}
