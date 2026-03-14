import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';

abstract interface class TelemetryHistoryRemoteDataSource {
  Future<TelemetryHistorySeries> getSeries({
    required String serial,
    required TelemetryHistoryQuery query,
  });
}
