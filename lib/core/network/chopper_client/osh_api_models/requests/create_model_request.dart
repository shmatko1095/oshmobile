final class CreateModelRequest {
  final String name;
  final String manufacturerId;
  final CreateModelInitialConfiguration initialConfiguration;

  CreateModelRequest({
    required this.name,
    required this.manufacturerId,
    required this.initialConfiguration,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'manufacturerId': manufacturerId,
        'initialConfiguration': initialConfiguration.toJson(),
      };
}

final class CreateModelInitialConfiguration {
  final CreateModelFirmwareCompatibility firmwareCompatibility;
  final Map<String, dynamic> configuration;
  final String? status;

  const CreateModelInitialConfiguration({
    required this.firmwareCompatibility,
    required this.configuration,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'firmwareCompatibility': firmwareCompatibility.toJson(),
      'configuration': configuration,
    };
    if (status != null && status!.isNotEmpty) {
      json['status'] = status;
    }
    return json;
  }
}

final class CreateModelFirmwareCompatibility {
  final CreateModelFirmwareVersion from;
  final CreateModelFirmwareVersion? to;

  const CreateModelFirmwareCompatibility({
    required this.from,
    this.to,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'from': from.toJson()};
    if (to != null) {
      json['to'] = to!.toJson();
    }
    return json;
  }
}

final class CreateModelFirmwareVersion {
  final int major;
  final int minor;

  const CreateModelFirmwareVersion({
    required this.major,
    required this.minor,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'major': major,
        'minor': minor,
      };
}
