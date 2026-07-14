part of 'device_facade.dart';

abstract interface class DeviceTelemetryHistoryApi
    implements TelemetryHistorySeriesReader, TelemetrySetpointHistoryReader {
  Future<TelemetryAggregate> getAggregate({
    required TelemetryAggregateQuery query,
  });
}
