import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/generated/l10n.dart';

typedef RestErrorMessageResolver = String Function(S s);

class RestErrorLocalizer {
  const RestErrorLocalizer._();

  static final Map<String, RestErrorMessageResolver> _resolvers =
      <String, RestErrorMessageResolver>{
    'validation_error': (s) => s.ApiValidationError,
    'invalid_argument': (s) => s.ApiValidationError,
    'out_of_range': (s) => s.ApiValidationError,
    'failed_precondition': (s) => s.ApiPreconditionFailed,
    'not_found': (s) => s.ApiNotFound,
    'already_exists': (s) => s.ApiConflict,
    'permission_denied': (s) => s.ApiPermissionDenied,
    'unauthenticated': (s) => s.ApiUnauthenticated,
    'service_unavailable': (s) => s.ApiServiceUnavailable,
    'deadline_exceeded': (s) => s.ApiTimeout,
    'resource_exhausted': (s) => s.ApiTooManyRequests,
    'internal_error': (s) => s.ApiInternalError,
    'invalid_token_format': (s) => s.DeleteAccountTokenInvalid,
    'token_not_found': (s) => s.DeleteAccountTokenNotFound,
    'token_used_or_expired': (s) => s.DeleteAccountTokenExpired,
  };

  static String resolveFailure(Failure failure, {String? fallback}) {
    return resolve(
      code: failure.code,
      fallback: fallback ?? failure.message,
    );
  }

  static String resolve({
    String? code,
    String? fallback,
  }) {
    final normalizedCode = code?.trim().toLowerCase();
    final l10n = _tryCurrent();
    final resolver = normalizedCode == null ? null : _resolvers[normalizedCode];

    if (resolver != null && l10n != null) {
      return resolver(l10n);
    }

    final normalizedFallback = fallback?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return l10n?.UnknownError ?? 'Unknown error';
  }

  static S? _tryCurrent() {
    try {
      return S.current;
    } catch (_) {
      return null;
    }
  }
}
