enum UserGuideTopic {
  thermostatLiveMetricsV1('thermostat_live_metrics_v1');

  const UserGuideTopic(this.storageKey);

  final String storageKey;

  static UserGuideTopic? fromStorageKey(String value) {
    for (final topic in values) {
      if (topic.storageKey == value) return topic;
    }
    return null;
  }
}
