import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';

class Device {
  final String id;
  final String sn;
  final String modelId;
  final DeviceUserData userData;
  final ConnectionInfo connectionInfo;

  const Device({
    required this.id,
    required this.sn,
    required this.modelId,
    required this.userData,
    required this.connectionInfo,
  });

  factory Device.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return Device(
      id: json['id'] ?? "",
      sn: json['serialNumber'] ?? "",
      modelId: json['modelId'] ?? "",
      userData: DeviceUserData.fromJson(json["userData"]),
      connectionInfo: ConnectionInfo.fromJson(json["connectionInfo"]),
    );
  }
}
