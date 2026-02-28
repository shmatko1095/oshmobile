import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/core/profile/models/control_binding.dart';

class ControlBindingRegistry {
  const ControlBindingRegistry(this.bundle);

  final DeviceProfileBundle bundle;

  ControlBinding? bindingFor(String controlId) => bundle.bindings[controlId];

  ControlBindingAction? readBinding(String controlId) =>
      bindingFor(controlId)?.read;

  ControlBindingAction? writeBinding(String controlId) =>
      bindingFor(controlId)?.write;

  String? featureFor(String controlId) {
    final binding = bindingFor(controlId);
    return binding?.write?.feature ?? binding?.read?.feature;
  }

  bool canRead(String controlId) {
    final binding = readBinding(controlId);
    if (binding == null) return false;
    if (!bundle.isControlEnabled(controlId)) return false;
    if (!_featureAllowed(controlId, binding)) return false;
    final domain = binding.domain;
    if (domain != null && domain.isNotEmpty && !bundle.canReadDomain(domain)) {
      return false;
    }
    if (binding.requires.isEmpty) return true;
    return binding.requires.every(bundle.negotiatedSchemas.contains);
  }

  bool canWrite(String controlId) {
    final binding = writeBinding(controlId);
    if (binding == null) return false;
    if (!bundle.isControlEnabled(controlId)) return false;
    if (!_featureAllowed(controlId, binding)) return false;
    final domain = binding.domain;
    final method = binding.method ?? '';
    if (domain != null && domain.isNotEmpty) {
      if (method.endsWith('.patch') && !bundle.canPatchDomain(domain)) {
        return false;
      }
      if (method.endsWith('.set') && !bundle.canSetDomain(domain)) {
        return false;
      }
    }
    if (binding.requires.isEmpty) return true;
    return binding.requires.every(bundle.negotiatedSchemas.contains);
  }

  bool isVisible(String controlId) {
    return canRead(controlId) || canWrite(controlId);
  }

  bool _featureAllowed(String controlId, ControlBindingAction binding) {
    final feature = binding.feature ?? featureFor(controlId);
    if (feature == null || feature.isEmpty) return true;

    final domain = binding.domain ?? readBinding(controlId)?.domain;
    if (domain == null || domain.isEmpty) return false;

    return bundle.supportsFeature(domain, feature);
  }
}
