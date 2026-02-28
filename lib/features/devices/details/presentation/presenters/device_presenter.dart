import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/unknown_config_presenter.dart';

abstract class DevicePresenter {
  Widget build(BuildContext context, Device device, DeviceProfileBundle bundle);
}

class DevicePresenterRegistry {
  final Map<String, DevicePresenter> _map;

  const DevicePresenterRegistry(this._map);

  DevicePresenter resolve(String modelId) => _map[modelId] ?? const UnknownConfigPresenter();
}
