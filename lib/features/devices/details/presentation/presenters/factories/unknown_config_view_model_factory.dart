import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/models/unknown_config_view_model.dart';

class UnknownConfigViewModelFactory {
  const UnknownConfigViewModelFactory();

  UnknownConfigViewModel build({
    required Device device,
    required DeviceConfigurationBundle bundle,
  }) {
    final alias = _resolveAlias(device);

    return UnknownConfigViewModel(
      alias: alias,
      meta: UnknownConfigMeta(
        isOnline: device.connectionInfo.online,
        serial: device.sn,
        modelId: device.modelId,
        modelName: device.modelName,
        layout: bundle.layout,
        configurationId: bundle.configurationId,
        revision: bundle.revision,
        status: bundle.status,
        firmwareVersion: bundle.firmwareVersion,
        deviceId: device.id,
        controlsCount: bundle.configuration.oshmobile.controls.length,
        widgetsCount: bundle.configuration.oshmobile.widgets.length,
        controlIds: List<String>.unmodifiable(
          bundle.configuration.oshmobile.controls.keys,
        ),
      ),
      actions: const <UnknownConfigAction>[
        UnknownConfigAction.refresh,
      ],
      tips: const <UnknownConfigTip>[
        UnknownConfigTip.ensureAppUpdated,
        UnknownConfigTip.checkNetwork,
        UnknownConfigTip.contactSupport,
      ],
    );
  }

  String _resolveAlias(Device device) {
    final alias = device.userData.alias.trim();
    if (alias.isNotEmpty) {
      return alias;
    }

    final serial = device.sn.trim();
    if (serial.isNotEmpty) {
      return serial;
    }

    final modelId = device.modelId.trim();
    if (modelId.isNotEmpty) {
      return modelId;
    }

    return device.id.trim();
  }
}
