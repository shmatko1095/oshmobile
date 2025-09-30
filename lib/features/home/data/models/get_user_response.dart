// import 'package:oshmobile/core/common/entities/device/device.dart';
//
// class GetUserResponse {
//   final List<Device> devices;
//
//   const GetUserResponse({
//     required this.devices,
//   });
//
//   factory GetUserResponse.fromJson(Map<String, dynamic>? json) {
//     json = json ?? {};
//     return GetUserResponse(
//       devices: (json['devices'] as List<dynamic>?)?.map((deviceJson) {
//             return Device.fromJson(deviceJson as Map<String, dynamic>);
//           }).toList() ??
//           [],
//     );
//   }
// }
