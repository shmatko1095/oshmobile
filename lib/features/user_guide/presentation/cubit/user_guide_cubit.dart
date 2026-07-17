import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/logging/app_log.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/domain/repositories/user_guide_progress_repository.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_session_source.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_state.dart';

class UserGuideCubit extends Cubit<UserGuideState> {
  UserGuideCubit({required UserGuideProgressRepository repository})
      : _repository = repository,
        super(const UserGuideState());

  final UserGuideProgressRepository _repository;
  Future<void>? _loadOperation;

  Future<void> load() => _loadOperation ??= _load();

  Future<void> completeTopic(UserGuideTopic topic) {
    return _markCompleted(topic, skipped: false);
  }

  Future<void> skipTopic(UserGuideTopic topic) {
    return _markCompleted(topic, skipped: true);
  }

  bool startAutomaticGuide([
    UserGuideTopic topic = UserGuideTopic.thermostatLiveMetricsV1,
  ]) {
    if (!state.isLoaded ||
        state.isGuideSessionActive ||
        !state.shouldShowAutomatically(topic)) {
      return false;
    }

    emit(state.copyWith(
      sessionSource: UserGuideSessionSource.automatic,
      sessionTopic: topic,
      sessionPageIndex: 0,
    ));
    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.userGuideAutoShown,
        parameters: <String, Object?>{'topic': topic.storageKey},
      ),
    );
    return true;
  }

  void startManualGuide([
    UserGuideTopic topic = UserGuideTopic.thermostatLiveMetricsV1,
  ]) {
    emit(state.copyWith(
      sessionSource: UserGuideSessionSource.manual,
      sessionTopic: topic,
      sessionPageIndex: 0,
    ));
    unawaited(
      OshAnalytics.logEvent(OshAnalyticsEvents.userGuideManualOpened),
    );
  }

  void selectPage(int index) {
    if (!state.isGuideSessionActive ||
        index < 0 ||
        index == state.sessionPageIndex) {
      return;
    }
    emit(state.copyWith(sessionPageIndex: index));
  }

  void finishManualGuide() {
    if (!state.isManualSessionActive) return;
    _finishManualSession();
  }

  Future<void> finishGuideSession({bool skipped = true}) async {
    if (!state.isGuideSessionActive) return;

    if (state.isManualSessionActive) {
      _finishManualSession();
      return;
    }

    final topic = state.sessionTopic!;
    final completedTopics = <UserGuideTopic>{
      ...state.completedTopics,
      topic,
    };
    emit(state.copyWith(
      completedTopics: completedTopics,
      clearSession: true,
    ));
    await _persistCompletedTopics(
      topic,
      completedTopics,
      skipped: skipped,
    );
  }

  void cancelGuideSession([
    UserGuideTopic? topic,
  ]) {
    if (!state.isGuideSessionActive ||
        (topic != null && state.sessionTopic != topic)) {
      return;
    }
    if (state.isManualSessionActive) {
      _finishManualSession();
      return;
    }
    emit(state.copyWith(clearSession: true));
  }

  void _finishManualSession() {
    final topic = state.sessionTopic;
    emit(state.copyWith(
      clearSession: true,
      sessionSuppressedTopics: topic == null
          ? state.sessionSuppressedTopics
          : <UserGuideTopic>{
              ...state.sessionSuppressedTopics,
              topic,
            },
    ));
  }

  Future<void> _load() async {
    try {
      final completedTopics = await _repository.loadCompletedTopics();
      emit(state.copyWith(
        isLoaded: true,
        completedTopics: completedTopics,
      ));
    } catch (error, stackTrace) {
      AppLog.error(
        'Failed to load user guide progress',
        error: error,
        stackTrace: stackTrace,
      );
      emit(state.copyWith(isLoaded: true));
    }
  }

  Future<void> _markCompleted(
    UserGuideTopic topic, {
    required bool skipped,
  }) async {
    if (state.completedTopics.contains(topic)) return;

    final completedTopics = <UserGuideTopic>{
      ...state.completedTopics,
      topic,
    };
    emit(state.copyWith(completedTopics: completedTopics));

    await _persistCompletedTopics(
      topic,
      completedTopics,
      skipped: skipped,
    );
  }

  Future<void> _persistCompletedTopics(
    UserGuideTopic topic,
    Set<UserGuideTopic> completedTopics, {
    required bool skipped,
  }) async {
    unawaited(
      OshAnalytics.logEvent(
        skipped
            ? OshAnalyticsEvents.userGuideTopicSkipped
            : OshAnalyticsEvents.userGuideTopicCompleted,
        parameters: <String, Object?>{'topic': topic.storageKey},
      ),
    );

    try {
      await _repository.saveCompletedTopics(completedTopics);
    } catch (error, stackTrace) {
      AppLog.error(
        'Failed to save user guide progress',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
