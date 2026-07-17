import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';

void main() {
  const topic = UserGuideTopic.thermostatLiveMetricsV1;

  test('topic stays available until its final host unregisters', () {
    final registry = UserGuideHostRegistry();
    final firstHost = Object();
    final secondHost = Object();

    registry
      ..registerHost(topic, firstHost)
      ..registerHost(topic, secondHost);

    expect(registry.hasHost(topic), isTrue);

    registry.unregisterHost(topic, firstHost);
    expect(registry.hasHost(topic), isTrue);

    registry.unregisterHost(topic, secondHost);
    expect(registry.hasHost(topic), isFalse);
  });

  test('registering the same host token is idempotent', () {
    final registry = UserGuideHostRegistry();
    final host = Object();

    registry
      ..registerHost(topic, host)
      ..registerHost(topic, host)
      ..unregisterHost(topic, host);

    expect(registry.hasHost(topic), isFalse);
  });
}
