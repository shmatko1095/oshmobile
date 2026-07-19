part of 'device_facade.dart';

abstract interface class DeviceTelemetryHistoryApi
    implements
        TelemetryHistorySeriesReader,
        TelemetrySetpointHistoryReader,
        EnergyUsageReader,
        HeatingUsageReader {
  Future<TelemetryAggregate> getAggregate({
    required TelemetryAggregateQuery query,
  });
}
