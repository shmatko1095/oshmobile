import 'package:oshmobile/core/common/entities/session_mode.dart';

class Session {
  final String accessToken;
  final String refreshToken;
  final String? authProvider;
  final String? tokenType;
  final DateTime? accessTokenExpiry;
  final DateTime? refreshTokenExpiry;
  final String? sessionState;
  final int? notBeforePolicy;
  final String? scope;
  final SessionMode? mode;

  Session({
    required this.accessToken,
    required this.refreshToken,
    this.authProvider,
    this.tokenType,
    this.accessTokenExpiry,
    this.refreshTokenExpiry,
    this.sessionState,
    this.notBeforePolicy,
    this.scope,
    this.mode,
  });

  String get typedAccessToken {
    final normalizedType = tokenType?.trim() ?? '';
    if (normalizedType.isEmpty) {
      return accessToken;
    }
    return '$normalizedType $accessToken';
  }

  bool get isDemoMode => mode == SessionMode.demo;

  /// Factory method to parse from JSON.
  factory Session.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Session(
      accessToken: json['access_token'] ?? "",
      refreshToken: json['refresh_token'] ?? "",
      authProvider: json['auth_provider']?.toString(),
      tokenType: json['token_type'] ?? "",
      accessTokenExpiry: _expiryFromNow(now, json['expires_in']),
      refreshTokenExpiry: _expiryFromNow(now, json['refresh_expires_in']),
      sessionState: json['session_state'] ?? "",
      notBeforePolicy: json['not-before-policy'] ?? 0,
      scope: json['scope'] ?? "",
      mode: SessionMode.fromJsonValue(json['mode']),
    );
  }

  /// Convert to JSON for storage or API communication.
  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'auth_provider': authProvider,
        'token_type': tokenType,
        'expires_in': accessTokenExpiry != null
            ? accessTokenExpiry!.difference(DateTime.now()).inSeconds
            : 0, // Remaining time
        'refresh_expires_in': refreshTokenExpiry != null
            ? refreshTokenExpiry!.difference(DateTime.now()).inSeconds
            : 0, // Remaining time
        'session_state': sessionState,
        'not-before-policy': notBeforePolicy,
        'scope': scope,
        'mode': mode?.jsonValue,
      };

  /// Validate if access token is still valid.
  bool get isAccessTokenValid {
    return DateTime.now().isBefore(accessTokenExpiry ?? DateTime.now());
  }

  /// Validate if refresh token is still valid.
  bool get isRefreshTokenValid {
    // If we don't know expiry (e.g. Google sign-in), fall back to "we have a non-empty refresh token".
    if (refreshTokenExpiry == null) {
      return refreshToken.isNotEmpty;
    }
    return DateTime.now().isBefore(refreshTokenExpiry!);
  }

  /// Create a copy of the session with modified fields.
  Session copyWith({
    String? accessToken,
    String? refreshToken,
    String? authProvider,
    String? tokenType,
    DateTime? accessTokenExpiry,
    DateTime? refreshTokenExpiry,
    String? sessionState,
    int? notBeforePolicy,
    String? scope,
    SessionMode? mode,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      authProvider: authProvider ?? this.authProvider,
      tokenType: tokenType ?? this.tokenType,
      accessTokenExpiry: accessTokenExpiry ?? this.accessTokenExpiry,
      refreshTokenExpiry: refreshTokenExpiry ?? this.refreshTokenExpiry,
      sessionState: sessionState ?? this.sessionState,
      notBeforePolicy: notBeforePolicy ?? this.notBeforePolicy,
      scope: scope ?? this.scope,
      mode: mode ?? this.mode,
    );
  }

  static DateTime? _expiryFromNow(DateTime now, dynamic rawSeconds) {
    final seconds = _readPositiveInt(rawSeconds);
    if (seconds == null) {
      return null;
    }
    return now.add(Duration(seconds: seconds));
  }

  static int? _readPositiveInt(dynamic raw) {
    if (raw is int) {
      return raw > 0 ? raw : null;
    }
    if (raw is num) {
      final rounded = raw.round();
      return rounded > 0 ? rounded : null;
    }
    if (raw is String) {
      final normalized = raw.trim();
      if (normalized.isEmpty) {
        return null;
      }
      final parsed =
          int.tryParse(normalized) ?? num.tryParse(normalized)?.round();
      if (parsed == null || parsed <= 0) {
        return null;
      }
      return parsed;
    }
    return null;
  }
}
