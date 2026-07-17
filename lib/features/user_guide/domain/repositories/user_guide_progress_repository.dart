import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';

abstract interface class UserGuideProgressRepository {
  Future<Set<UserGuideTopic>> loadCompletedTopics();

  Future<void> saveCompletedTopics(Set<UserGuideTopic> topics);
}
