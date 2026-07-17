import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/domain/repositories/user_guide_progress_repository.dart';

class TestUserGuideProgressRepository implements UserGuideProgressRepository {
  TestUserGuideProgressRepository({
    Set<UserGuideTopic>? completedTopics,
    this.throwOnLoad = false,
    this.throwOnSave = false,
  }) : completedTopics = completedTopics ?? <UserGuideTopic>{};

  Set<UserGuideTopic> completedTopics;
  bool throwOnLoad;
  bool throwOnSave;
  int saveCount = 0;

  @override
  Future<Set<UserGuideTopic>> loadCompletedTopics() async {
    if (throwOnLoad) throw StateError('load failed');
    return Set<UserGuideTopic>.of(completedTopics);
  }

  @override
  Future<void> saveCompletedTopics(Set<UserGuideTopic> topics) async {
    saveCount++;
    if (throwOnSave) throw StateError('save failed');
    completedTopics = Set<UserGuideTopic>.of(topics);
  }
}
