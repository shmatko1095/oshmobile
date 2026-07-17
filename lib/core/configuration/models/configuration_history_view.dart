class ConfigurationHistoryView {
  const ConfigurationHistoryView({
    required this.id,
    required this.title,
    required this.seriesIds,
  });

  factory ConfigurationHistoryView.fromJson(Map<String, dynamic> json) {
    final rawSeriesIds = json['series_ids'];
    return ConfigurationHistoryView(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      seriesIds: rawSeriesIds is List
          ? rawSeriesIds
              .map((item) => item.toString())
              .where((id) => id.trim().isNotEmpty)
              .toList(growable: false)
          : const <String>[],
    );
  }

  final String id;
  final String title;
  final List<String> seriesIds;
}
