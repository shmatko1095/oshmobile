final class TelemetryDecodeIssue {
  final String path;
  final String reason;

  const TelemetryDecodeIssue({
    required this.path,
    required this.reason,
  });

  String get signature => '$path:$reason';
}
