import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/error/exceptions.dart';

class RestResponseErrorMapper {
  const RestResponseErrorMapper._();

  static ServerException toServerException(Response<dynamic> response) {
    final map = decodeMap(response.body) ?? decodeMap(response.error);
    final metadata = _metadata(map);
    final code = _errorCode(map, metadata);
    final message = _errorMessage(map, metadata, response.statusCode);
    final details = _responseDetails(metadata);

    return ServerException(
      message,
      code: code,
      details: details,
    );
  }

  static void throwIfFailed(Response<dynamic> response) {
    if (!response.isSuccessful) {
      throw toServerException(response);
    }
  }

  static String messageFromResponse(Response<dynamic> response) {
    return toServerException(response).message;
  }

  static Map<String, dynamic>? decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static List<dynamic>? decodeList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  static String? _errorCode(
    Map<String, dynamic>? map,
    Map<String, String> details,
  ) {
    final direct = _readNonBlank(map, 'code');
    if (direct != null) return direct;

    final nested = details['code'];
    if (nested != null && nested.trim().isNotEmpty) return nested.trim();

    final legacyReason = _readNonBlank(map, 'reason');
    if (legacyReason != null && _looksLikeCode(legacyReason)) {
      return legacyReason;
    }

    return null;
  }

  static String _errorMessage(
    Map<String, dynamic>? map,
    Map<String, String> details,
    int statusCode,
  ) {
    for (final key in ['message', 'detail', 'error']) {
      final value = _readNonBlank(map, key);
      if (value != null) return value;
    }

    final nestedMessage = details['message'];
    if (nestedMessage != null && nestedMessage.trim().isNotEmpty) {
      return nestedMessage.trim();
    }

    final legacyReason = _readNonBlank(map, 'reason');
    if (legacyReason != null && !_looksLikeCode(legacyReason)) {
      return legacyReason;
    }

    return 'HTTP $statusCode';
  }

  static Map<String, String> _metadata(Map<String, dynamic>? map) {
    final details = <String, String>{};
    _putAllStringValues(details, map?['details']);
    _putAllStringValues(details, map?['grpc_response']);
    return Map.unmodifiable(details);
  }

  static Map<String, String> _responseDetails(Map<String, String> metadata) {
    final details = Map<String, String>.of(metadata);
    details.remove('code');
    details.remove('message');
    details.remove('reason');
    details.remove('timestamp');
    return Map.unmodifiable(details);
  }

  static void _putAllStringValues(Map<String, String> target, dynamic raw) {
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      final key = entry.key?.toString().trim();
      final value = entry.value?.toString().trim();
      if (key == null || key.isEmpty || value == null || value.isEmpty) {
        continue;
      }
      target[key] = value;
    }
  }

  static String? _readNonBlank(Map<String, dynamic>? map, String key) {
    final value = map?[key]?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static bool _looksLikeCode(String value) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value.trim());
  }
}
