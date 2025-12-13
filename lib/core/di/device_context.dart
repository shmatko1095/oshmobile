import 'package:oshmobile/core/common/entities/device/device.dart';

/// Immutable context for a *selected device*.
///
/// This object is registered inside GetIt "device" scope and is used by
/// device-scoped cubits and helpers.
class DeviceContext {
  final String deviceId;
  final String deviceSn;
  final String modelId;

  const DeviceContext({
    required this.deviceId,
    required this.deviceSn,
    required this.modelId,
  });

  factory DeviceContext.fromDevice(Device d) => DeviceContext(
        deviceId: d.id,
        deviceSn: d.sn,
        modelId: d.modelId,
      );
}
