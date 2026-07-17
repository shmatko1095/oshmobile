import 'package:flutter/foundation.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_session_source.dart';

@immutable
class UserGuideState {
  const UserGuideState({
    this.isLoaded = false,
    this.completedTopics = const <UserGuideTopic>{},
    this.sessionSource,
    this.sessionTopic,
    this.sessionPageIndex = 0,
    this.sessionSuppressedTopics = const <UserGuideTopic>{},
  });

  final bool isLoaded;
  final Set<UserGuideTopic> completedTopics;
  final UserGuideSessionSource? sessionSource;
  final UserGuideTopic? sessionTopic;
  final int sessionPageIndex;
  final Set<UserGuideTopic> sessionSuppressedTopics;

  bool get isGuideSessionActive =>
      sessionSource != null && sessionTopic != null;

  bool get isAutomaticSessionActive =>
      sessionSource == UserGuideSessionSource.automatic && sessionTopic != null;

  bool get isManualSessionActive =>
      sessionSource == UserGuideSessionSource.manual && sessionTopic != null;

  bool isCompleted(UserGuideTopic topic) => completedTopics.contains(topic);

  bool shouldShowAutomatically(UserGuideTopic topic) =>
      !isCompleted(topic) && !sessionSuppressedTopics.contains(topic);

  UserGuideState copyWith({
    bool? isLoaded,
    Set<UserGuideTopic>? completedTopics,
    UserGuideSessionSource? sessionSource,
    UserGuideTopic? sessionTopic,
    bool clearSession = false,
    int? sessionPageIndex,
    Set<UserGuideTopic>? sessionSuppressedTopics,
  }) {
    return UserGuideState(
      isLoaded: isLoaded ?? this.isLoaded,
      completedTopics: Set<UserGuideTopic>.unmodifiable(
        completedTopics ?? this.completedTopics,
      ),
      sessionSource: clearSession ? null : sessionSource ?? this.sessionSource,
      sessionTopic: clearSession ? null : sessionTopic ?? this.sessionTopic,
      sessionPageIndex:
          clearSession ? 0 : sessionPageIndex ?? this.sessionPageIndex,
      sessionSuppressedTopics: Set<UserGuideTopic>.unmodifiable(
        sessionSuppressedTopics ?? this.sessionSuppressedTopics,
      ),
    );
  }
}
