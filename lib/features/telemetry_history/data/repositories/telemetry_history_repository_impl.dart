import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';

class TelemetryHistoryRepositoryImpl implements TelemetryHistoryRepository {
  const TelemetryHistoryRepositoryImpl({
    required TelemetryHistoryRemoteDataSource remote,
  }) : _remote = remote;

  final TelemetryHistoryRemoteDataSource _remote;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String serial,
    required TelemetryHistoryQuery query,
  }) {
    return _remote.getSeries(serial: serial, query: query);
  }
}
