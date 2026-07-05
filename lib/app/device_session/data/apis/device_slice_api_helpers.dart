import 'dart:async';

import 'package:oshmobile/core/logging/app_log.dart';

Stream<T> watchWithCurrent<T>({
  required T? current,
  required Stream<T> updates,
}) {
  return Stream<T>.multi((controller) {
    final value = current;
    if (value != null) {
      controller.add(value);
    }

    final sub = updates.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = () => sub.cancel();
  });
}

String deviceApiErrorMessage(Object error) {
  if (error is TimeoutException) {
    return error.message ?? 'Timeout';
  }
  return error.toString();
}

Future<void> cancelSubscriptionAndLog(
  StreamSubscription<dynamic>? subscription, {
  required String owner,
}) async {
  await logAndIgnoreFuture(
    subscription?.cancel() ?? Future<void>.value(),
    owner: owner,
    operation: 'cancel subscription',
  );
}

Future<void> closeStreamControllerAndLog(
  StreamController<dynamic> controller, {
  required String owner,
}) async {
  await logAndIgnoreFuture(
    controller.close(),
    owner: owner,
    operation: 'close stream',
  );
}

Future<void> logAndIgnoreFuture(
  Future<void> future, {
  required String owner,
  required String operation,
}) async {
  try {
    await future;
  } catch (error, stackTrace) {
    AppLog.error(
      '$owner: $operation failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
