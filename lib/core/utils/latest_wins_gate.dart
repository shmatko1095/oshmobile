import 'dart:async';

/// Tracks latest-wins operations by key.
///
/// When a new token is started for the same key, the previous one is cancelled.
class LatestWinsGate {
  final Map<String, _LatestWinsSlot> _slots = {};

  LatestWinsToken start(String key) {
    final prev = _slots[key];
    prev?.supersede();

    final nextToken = (prev?.token ?? 0) + 1;
    final cancel = Completer<void>();
    _slots[key] = _LatestWinsSlot(token: nextToken, cancelled: cancel);

    return LatestWinsToken(key: key, token: nextToken, cancelled: cancel.future);
  }

  bool isCurrent(LatestWinsToken token) => _slots[token.key]?.token == token.token;

  void clear() {
    for (final slot in _slots.values) {
      slot.supersede();
    }
    _slots.clear();
  }
}

class LatestWinsToken {
  final String key;
  final int token;
  final Future<void> cancelled;

  const LatestWinsToken({
    required this.key,
    required this.token,
    required this.cancelled,
  });
}

class _LatestWinsSlot {
  final int token;
  final Completer<void> cancelled;

  _LatestWinsSlot({required this.token, required this.cancelled});

  void supersede() {
    if (cancelled.isCompleted) return;
    cancelled.complete();
  }
}
