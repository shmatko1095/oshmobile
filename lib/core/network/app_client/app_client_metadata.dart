class AppClientMetadata {
  const AppClientMetadata({
    required this.platform,
    required this.appVersion,
    required this.build,
  });

  final String platform;
  final String appVersion;
  final int? build;
}
