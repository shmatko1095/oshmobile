/// Simple serial async executor.
/// Guarantees tasks are executed one-by-one in call order.
///
/// Usage:
///   final _serial = SerialExecutor();
///   Future<void> foo() => _serial.run(() async { ... });
class SerialExecutor {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() op) {
    final next = _tail.then((_) => op());
    // Keep chain alive even if op fails.
    _tail = next.then((_) {}, onError: (_) {});
    return next;
  }
}
