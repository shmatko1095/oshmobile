class OshConfiguration {
  final String type;

  const OshConfiguration({
    required this.type,
  });

  factory OshConfiguration.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return OshConfiguration(
      type: json['type'] ?? "",
    );
  }
}
