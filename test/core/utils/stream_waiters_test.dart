import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';

void main() {
  test('firstWithTimeout cancels subscription on timeout', () async {
    var canceled = false;

    final ctrl = StreamController<int>(
      onCancel: () {
        canceled = true;
      },
    );

    try {
      await firstWithTimeout(ctrl.stream, const Duration(milliseconds: 30));
      fail('Expected TimeoutException');
    } on TimeoutException {
      // expected
    }

    // Allow cancellation microtasks to run.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(canceled, isTrue);
    await ctrl.close();
  });

  test('firstWhereWithTimeout returns match and cancels subscription', () async {
    var canceled = false;

    final ctrl = StreamController<int>(
      onCancel: () {
        canceled = true;
      },
    );

    // Emit values asynchronously.
    unawaited(Future<void>(() async {
      ctrl.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      ctrl.add(2);
    }));

    final v = await firstWhereWithTimeout<int>(
      ctrl.stream,
      (e) => e == 2,
      const Duration(milliseconds: 200),
    );

    expect(v, 2);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(canceled, isTrue);

    await ctrl.close();
  });

  test('firstWhereWithTimeout cancels subscription when predicate throws', () async {
    var canceled = false;

    final ctrl = StreamController<int>(
      onCancel: () {
        canceled = true;
      },
    );

    unawaited(Future<void>(() async {
      ctrl.add(1);
    }));

    try {
      await firstWhereWithTimeout<int>(
        ctrl.stream,
        (e) => throw StateError('boom'),
        const Duration(milliseconds: 200),
      );
      fail('Expected StateError');
    } on StateError {
      // expected
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(canceled, isTrue);

    await ctrl.close();
  });
}
