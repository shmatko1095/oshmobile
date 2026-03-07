import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';

class ControlRegistry {
  const ControlRegistry(this.bundle);

  final DeviceConfigurationBundle bundle;

  ConfigurationControl? control(String controlId) =>
      bundle.configuration.oshmobile.controls[controlId];

  ConfigurationReadBinding? readBinding(String controlId) =>
      control(controlId)?.read;

  ConfigurationWriteBinding? writeBinding(String controlId) =>
      control(controlId)?.write;

  Set<String> readDomains(String controlId) {
    final binding = readBinding(controlId);
    if (binding == null) return const <String>{};

    switch (binding.kind) {
      case 'domain_path':
        final domain = binding.domain;
        return domain == null || domain.isEmpty
            ? const <String>{}
            : <String>{domain};
      case 'collection':
      case 'collection_item_field':
        final collectionId = binding.collection;
        if (collectionId == null || collectionId.isEmpty) {
          return const <String>{};
        }
        final collection =
            bundle.configuration.oshmobile.collections[collectionId];
        if (collection == null) return const <String>{};
        return collection.sources.values
            .map((source) => source.domain)
            .where((value) => value.isNotEmpty)
            .toSet();
      case 'schedule_current_target':
      case 'schedule_next_target':
        return const <String>{'schedule'};
      default:
        return const <String>{};
    }
  }

  bool canRead(String controlId) {
    if (readBinding(controlId) == null) return false;
    final domains = readDomains(controlId);
    return domains.every(bundle.canReadDomain);
  }

  bool canWrite(String controlId) {
    final binding = writeBinding(controlId);
    if (binding == null) return false;
    if (binding.kind != 'patch_field') return false;
    return bundle.canPatchDomain(binding.domain);
  }

  bool isVisible(String controlId) => canRead(controlId) || canWrite(controlId);
}
