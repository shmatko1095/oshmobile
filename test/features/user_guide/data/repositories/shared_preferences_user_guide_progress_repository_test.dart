import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/user_guide/data/repositories/shared_preferences_user_guide_progress_repository.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads known topics and safely ignores unknown stored identifiers',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesUserGuideProgressRepository.completedTopicsKey: <String>[
        UserGuideTopic.thermostatLiveMetricsV1.storageKey,
        'future_unknown_topic',
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    final repository =
        SharedPreferencesUserGuideProgressRepository(preferences);

    expect(
      await repository.loadCompletedTopics(),
      <UserGuideTopic>{UserGuideTopic.thermostatLiveMetricsV1},
    );
  });

  test('saves versioned topic identifiers', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository =
        SharedPreferencesUserGuideProgressRepository(preferences);

    await repository.saveCompletedTopics(
      <UserGuideTopic>{UserGuideTopic.thermostatLiveMetricsV1},
    );

    expect(
      preferences.getStringList(
        SharedPreferencesUserGuideProgressRepository.completedTopicsKey,
      ),
      <String>[UserGuideTopic.thermostatLiveMetricsV1.storageKey],
    );
  });
}
