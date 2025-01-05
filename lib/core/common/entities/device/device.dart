import 'package:oshmobile/core/common/entities/device/customer_data.dart';
import 'package:oshmobile/core/common/entities/device/info.dart';
import 'package:oshmobile/core/common/entities/device/model.dart';
import 'package:oshmobile/core/common/entities/device/status.dart';

class Device {
  final String uuid;
  final String sn;
  final Model model;
  final CustomerData customersData;
  final Info info;
  final Status status;

  const Device({
    required this.uuid,
    required this.sn,
    required this.model,
    required this.customersData,
    required this.info,
    required this.status,
  });

  factory Device.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return Device(
      uuid: json['uuid'] ?? "",
      sn: json['name'] ?? "",
      model: Model.fromJson(json["model"]),
      customersData: CustomerData.fromJson(json["customersData"]),
      info: Info.fromJson(json["info"]),
      status: Status.fromJson(json["status"]),
    );
  }
}
