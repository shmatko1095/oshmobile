import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';

import '../../test_user_guide_progress_repository.dart';

void main() {
  test('loads persisted completion state', () async {
    final repository = TestUserGuideProgressRepository(
      completedTopics: <UserGuideTopic>{
        UserGuideTopic.thermostatLiveMetricsV1,
      },
    );
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isLoaded, isTrue);
    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isTrue,
    );
  });

  test('completes a topic optimistically and persists it', () async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.completeTopic(UserGuideTopic.thermostatLiveMetricsV1);

    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isTrue,
    );
    expect(repository.saveCount, 1);
    expect(
      repository.completedTopics,
      contains(UserGuideTopic.thermostatLiveMetricsV1),
    );
  });

  test('storage failures do not roll back in-session completion', () async {
    final repository = TestUserGuideProgressRepository(throwOnSave: true);
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.skipTopic(UserGuideTopic.thermostatLiveMetricsV1);

    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isTrue,
    );
  });

  test('manual guide session does not complete automatic topics', () async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();

    cubit.startManualGuide();
    cubit.selectPage(2);
    expect(cubit.state.isManualSessionActive, isTrue);
    expect(
      cubit.state.sessionTopic,
      UserGuideTopic.thermostatLiveMetricsV1,
    );
    expect(cubit.state.sessionPageIndex, 2);

    cubit.finishManualGuide();
    expect(cubit.state.isManualSessionActive, isFalse);
    expect(cubit.state.sessionTopic, isNull);
    expect(cubit.state.sessionPageIndex, 0);
    expect(cubit.state.completedTopics, isEmpty);
    expect(
      cubit.state.shouldShowAutomatically(
        UserGuideTopic.thermostatLiveMetricsV1,
      ),
      isFalse,
    );
  });

  test('automatic guide uses a session and persists only when it exits',
      () async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.startAutomaticGuide(), isTrue);
    expect(cubit.state.isAutomaticSessionActive, isTrue);
    expect(
      cubit.state.sessionTopic,
      UserGuideTopic.thermostatLiveMetricsV1,
    );
    expect(cubit.state.sessionPageIndex, 0);
    expect(repository.saveCount, 0);

    cubit.selectPage(2);
    expect(cubit.state.sessionPageIndex, 2);
    await cubit.finishGuideSession();

    expect(cubit.state.isGuideSessionActive, isFalse);
    expect(
      cubit.state.isCompleted(UserGuideTopic.thermostatLiveMetricsV1),
      isTrue,
    );
    expect(repository.saveCount, 1);
  });

  test('cancelling automatic session leaves it eligible for another host',
      () async {
    final repository = TestUserGuideProgressRepository();
    final cubit = UserGuideCubit(repository: repository);
    addTearDown(cubit.close);
    await cubit.load();

    cubit.startAutomaticGuide();
    cubit.selectPage(1);
    cubit.cancelGuideSession(UserGuideTopic.thermostatLiveMetricsV1);

    expect(cubit.state.isGuideSessionActive, isFalse);
    expect(cubit.state.completedTopics, isEmpty);
    expect(cubit.state.sessionSuppressedTopics, isEmpty);
    expect(
      cubit.state.shouldShowAutomatically(
        UserGuideTopic.thermostatLiveMetricsV1,
      ),
      isTrue,
    );
    expect(repository.saveCount, 0);
  });
}
