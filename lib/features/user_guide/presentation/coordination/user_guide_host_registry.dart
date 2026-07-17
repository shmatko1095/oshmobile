import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';

class UserGuideHostRegistry {
  final Map<UserGuideTopic, Set<Object>> _hostsByTopic =
      <UserGuideTopic, Set<Object>>{};

  bool hasHost(UserGuideTopic topic) =>
      _hostsByTopic[topic]?.isNotEmpty ?? false;

  void registerHost(UserGuideTopic topic, Object hostToken) {
    _hostsByTopic.putIfAbsent(topic, () => <Object>{}).add(hostToken);
  }

  void unregisterHost(UserGuideTopic topic, Object hostToken) {
    final hosts = _hostsByTopic[topic];
    if (hosts == null) return;
    hosts.remove(hostToken);
    if (hosts.isEmpty) _hostsByTopic.remove(topic);
  }
}
