import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/domain/repositories/user_guide_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesUserGuideProgressRepository
    implements UserGuideProgressRepository {
  SharedPreferencesUserGuideProgressRepository(this._preferences);

  static const completedTopicsKey = 'osh.user_guide.completed_topics.v1';

  final SharedPreferences _preferences;

  @override
  Future<Set<UserGuideTopic>> loadCompletedTopics() async {
    final stored = _preferences.getStringList(completedTopicsKey);
    if (stored == null) return <UserGuideTopic>{};

    return stored
        .map(UserGuideTopic.fromStorageKey)
        .whereType<UserGuideTopic>()
        .toSet();
  }

  @override
  Future<void> saveCompletedTopics(Set<UserGuideTopic> topics) async {
    final values = topics.map((topic) => topic.storageKey).toList()..sort();
    final saved = await _preferences.setStringList(completedTopicsKey, values);
    if (!saved) {
      throw StateError('SharedPreferences rejected user guide progress');
    }
  }
}
