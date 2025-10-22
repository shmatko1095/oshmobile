import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/unknown_config_presenter.dart';

import '../models/osh_config.dart';

abstract class DevicePresenter {
  Widget build(BuildContext context, Device device, OshConfig cfg);
}

class DevicePresenterRegistry {
  final Map<String, DevicePresenter> _map;

  const DevicePresenterRegistry(this._map);

  DevicePresenter resolve(String modelId) => _map[modelId] ?? const UnknownConfigPresenter();
}
