enum TelemetryUsageBucket {
  hour('1h'),
  day('1d'),
  month('1mo');

  const TelemetryUsageBucket(this.wireValue);

  final String wireValue;
}
