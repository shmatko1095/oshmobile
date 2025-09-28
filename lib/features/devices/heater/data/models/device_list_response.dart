import 'package:oshmobile/core/common/entities/device/device.dart';

class DeviceListResponse {
  final String userUuid;
  final List<Device> devices;

  const DeviceListResponse({
    required this.userUuid,
    required this.devices,
  });

  factory DeviceListResponse.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return DeviceListResponse(
      userUuid: json['uuid'] ?? "",
      devices: (json['devices'] as List<dynamic>?)?.map((deviceJson) {
            return Device.fromJson(deviceJson as Map<String, dynamic>);
          }).toList() ??
          [],
    );
  }
}
