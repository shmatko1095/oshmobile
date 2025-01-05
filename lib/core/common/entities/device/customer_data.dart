class CustomerData {
  final String uuid;
  final String roomHint;
  final String name;

  const CustomerData({
    required this.uuid,
    required this.roomHint,
    required this.name,
  });

  factory CustomerData.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return CustomerData(
      uuid: json['uuid'] ?? "",
      roomHint: json['roomHint'] ?? "",
      name: json['name'] ?? "",
    );
  }

//toJson, copyWith
}
