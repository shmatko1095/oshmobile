class Status {
  final bool online;
  final String timestamp;

  const Status({
    required this.online,
    required this.timestamp,
  });

  factory Status.fromJson(Map<String, dynamic>? json) {
    json = json ?? {};
    return Status(
      online: json['online'] ?? false,
      timestamp: json['timestamp'] ?? "",
    );
  }
}
