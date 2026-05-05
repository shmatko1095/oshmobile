import 'package:oshmobile/core/network/mqtt/json_rpc_errors.dart';
import 'package:oshmobile/generated/l10n.dart';

typedef MqttErrorMessageResolver = String Function(S s);

class MqttErrorLocalizer {
  const MqttErrorLocalizer._();

  static final Map<int, MqttErrorMessageResolver> _resolvers =
      <int, MqttErrorMessageResolver>{
    -32005: (s) => s.MqttOperationNotAllowed,
    -32003: (s) => s.MqttUnsupportedSchema,
    -32602: (s) => s.MqttInvalidParams,
    -32601: (s) => s.MqttMethodNotFound,
    -32001: (s) => s.MqttDeviceBusy,
  };

  static String resolveException(JsonRpcException error) {
    return resolve(code: error.code, fallback: error.message);
  }

  static String resolve({
    required int code,
    String? fallback,
  }) {
    final l10n = _tryCurrent();
    final resolver = _resolvers[code];

    if (resolver != null && l10n != null) {
      return resolver(l10n);
    }

    final normalizedFallback = fallback?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return l10n?.MqttStatusError ?? 'Error';
  }

  static S? _tryCurrent() {
    try {
      return S.current;
    } catch (_) {
      return null;
    }
  }
}
