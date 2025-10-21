import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';

import '../models/osh_config.dart';

abstract class DevicePresenter {
  Widget build(BuildContext context, Device device, OshConfig cfg);
}

class DevicePresenterRegistry {
  final Map<String, DevicePresenter> _map;

  const DevicePresenterRegistry(this._map);

  DevicePresenter resolve(String modelId) => _map[modelId] ?? const GenericThermostatPresenter();
}

class GenericThermostatPresenter implements DevicePresenter {
  const GenericThermostatPresenter();

  @override
  Widget build(BuildContext context, Device device, OshConfig cfg) {
    return Scaffold(
      appBar: AppBar(title: Text(device.userData.alias.isEmpty ? device.sn : device.userData.alias)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            if (cfg.has('sensor.temperature')) _Card(title: 'Temperature', value: '— °C'),
            if (cfg.has('setting.target_temperature')) _Card(title: 'Target', value: '— °C'),
            if (cfg.has('switch.heating'))
              _Card(title: 'Heating', value: device.connectionInfo.online ? 'On?' : 'Off?'),
            if (cfg.has('sensor.humidity')) _Card(title: 'Humidity', value: '— %'),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String value;

  const _Card({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18)),
        ]),
      ),
    );
  }
}
