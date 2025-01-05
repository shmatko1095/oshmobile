import 'package:oshmobile/core/common/entities/device/osh_configuration.dart';

class Configuration {
  final String uuid;
  final String name;
  final String description;
  final String googleJson;
  final OshConfiguration osh;

  const Configuration({
    required this.uuid,
    required this.name,
    required this.description,
    required this.googleJson,
    required this.osh,
  });

  factory Configuration.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return Configuration(
      uuid: json['uuid'] ?? "",
      name: json['name'] ?? "",
      description: json['description'] ?? "",
      googleJson: (json['google'] ?? "").toString(),
      osh: OshConfiguration.fromJson(json["osh"]),
    );
  }
}
