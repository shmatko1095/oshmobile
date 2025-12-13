import 'dart:async';

/// Stream waiting helpers that *always* cancel the underlying subscription.
///
/// Why not `stream.first.timeout(...)`?
/// `Future.timeout()` does not cancel the stream subscription on timeout,
/// which can leak listeners (and for MQTT/BLE scans, keep subscriptions active).

/// Awaits the first event from [stream] with an absolute [timeout].
///
/// On timeout, the underlying subscription is cancelled before completing
/// with [TimeoutException].
Future<T> firstWithTimeout<T>(
  Stream<T> stream,
  Duration timeout, {
  String? timeoutMessage,
  String? doneMessage,
}) {
  final completer = Completer<T>();
  Timer? timer;
  late final StreamSubscription<T> sub;

  Future<void> _cancelSub() async {
    try {
      await sub.cancel();
    } catch (_) {
      // Best-effort.
    }
  }

  void finishValue(T value) {
    if (completer.isCompleted) return;
    timer?.cancel();
    completer.complete(value);
    unawaited(_cancelSub());
  }

  void finishError(Object error, [StackTrace? st]) {
    if (completer.isCompleted) return;
    timer?.cancel();
    completer.completeError(error, st);
    unawaited(_cancelSub());
  }

  sub = stream.listen(
    finishValue,
    onError: (Object e, StackTrace st) => finishError(e, st),
    onDone: () => finishError(StateError(doneMessage ?? 'Stream closed before first event')),
    cancelOnError: false,
  );

  timer = Timer(timeout, () {
    finishError(TimeoutException(timeoutMessage ?? 'Timeout waiting for first event', timeout));
  });

  return completer.future;
}

/// Awaits the first event from [stream] that matches [predicate] with an
/// absolute [timeout].
///
/// On timeout, the underlying subscription is cancelled before completing
/// with [TimeoutException].
Future<T> firstWhereWithTimeout<T>(
  Stream<T> stream,
  bool Function(T) predicate,
  Duration timeout, {
  String? timeoutMessage,
  String? doneMessage,
}) {
  final completer = Completer<T>();
  Timer? timer;
  late final StreamSubscription<T> sub;

  Future<void> _cancelSub() async {
    try {
      await sub.cancel();
    } catch (_) {
      // Best-effort.
    }
  }

  void finishValue(T value) {
    if (completer.isCompleted) return;
    timer?.cancel();
    completer.complete(value);
    unawaited(_cancelSub());
  }

  void finishError(Object error, [StackTrace? st]) {
    if (completer.isCompleted) return;
    timer?.cancel();
    completer.completeError(error, st);
    unawaited(_cancelSub());
  }

  sub = stream.listen(
    (event) {
      if (completer.isCompleted) return;
      bool ok;
      try {
        ok = predicate(event);
      } catch (e, st) {
        finishError(e, st);
        return;
      }
      if (!ok) return;
      finishValue(event);
    },
    onError: (Object e, StackTrace st) => finishError(e, st),
    onDone: () => finishError(StateError(doneMessage ?? 'Stream closed before match')),
    cancelOnError: false,
  );

  timer = Timer(timeout, () {
    finishError(TimeoutException(timeoutMessage ?? 'Timeout waiting for match', timeout));
  });

  return completer.future;
}
