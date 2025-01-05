class Manufacturer {
  final String uuid;
  final String name;

  const Manufacturer({
    required this.uuid,
    required this.name,
  });

  factory Manufacturer.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return Manufacturer(
      uuid: json['uuid'] ?? "",
      name: json['name'] ?? "",
    );
  }
}
