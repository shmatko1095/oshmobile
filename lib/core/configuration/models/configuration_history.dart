import 'package:oshmobile/core/configuration/models/configuration_history_series.dart';
import 'package:oshmobile/core/configuration/models/configuration_history_view.dart';

class ConfigurationHistory {
  const ConfigurationHistory({
    required this.series,
    required this.views,
  });

  factory ConfigurationHistory.fromJson(Map<String, dynamic> json) {
    final series = <String, ConfigurationHistorySeries>{};
    final rawSeries = json['series'];
    if (rawSeries is List) {
      for (final raw in rawSeries) {
        if (raw is! Map) continue;
        final item = ConfigurationHistorySeries.fromJson(
          raw.cast<String, dynamic>(),
        );
        if (item.id.isEmpty) continue;
        series[item.id] = item;
      }
    }

    final views = <ConfigurationHistoryView>[];
    final rawViews = json['views'];
    if (rawViews is List) {
      for (final raw in rawViews) {
        if (raw is! Map) continue;
        final item = ConfigurationHistoryView.fromJson(
          raw.cast<String, dynamic>(),
        );
        if (item.id.isEmpty || item.seriesIds.isEmpty) continue;
        views.add(item);
      }
    }

    return ConfigurationHistory(
      series: Map<String, ConfigurationHistorySeries>.unmodifiable(series),
      views: List<ConfigurationHistoryView>.unmodifiable(views),
    );
  }

  static const empty = ConfigurationHistory(
    series: <String, ConfigurationHistorySeries>{},
    views: <ConfigurationHistoryView>[],
  );

  final Map<String, ConfigurationHistorySeries> series;
  final List<ConfigurationHistoryView> views;
}
