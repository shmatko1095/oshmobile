class Session {
  final String accessToken;
  final String refreshToken;
  final String? tokenType;
  final DateTime? accessTokenExpiry;
  final DateTime? refreshTokenExpiry;
  final String? sessionState;
  final int? notBeforePolicy;
  final String? scope;

  Session({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType,
    this.accessTokenExpiry,
    this.refreshTokenExpiry,
    this.sessionState,
    this.notBeforePolicy,
    this.scope,
  });

  String get typedAccessToken => "$tokenType $accessToken";

  /// Factory method to parse from JSON.
  factory Session.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Session(
      accessToken: json['access_token'] ?? "",
      refreshToken: json['refresh_token'] ?? "",
      tokenType: json['token_type'] ?? "",
      accessTokenExpiry: now.add(
        Duration(seconds: json['expires_in'] ?? 0),
      ),
      refreshTokenExpiry: now.add(
        Duration(seconds: json['refresh_expires_in'] ?? 0),
      ),
      sessionState: json['session_state'] ?? "",
      notBeforePolicy: json['not-before-policy'] ?? 0,
      scope: json['scope'] ?? "",
    );
  }

  /// Convert to JSON for storage or API communication.
  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': tokenType,
        'expires_in':
            accessTokenExpiry != null ? accessTokenExpiry!.difference(DateTime.now()).inSeconds : 0, // Remaining time
        'refresh_expires_in':
            refreshTokenExpiry != null ? refreshTokenExpiry!.difference(DateTime.now()).inSeconds : 0, // Remaining time
        'session_state': sessionState,
        'not-before-policy': notBeforePolicy,
        'scope': scope,
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
    String? tokenType,
    DateTime? accessTokenExpiry,
    DateTime? refreshTokenExpiry,
    String? sessionState,
    int? notBeforePolicy,
    String? scope,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      accessTokenExpiry: accessTokenExpiry ?? this.accessTokenExpiry,
      refreshTokenExpiry: refreshTokenExpiry ?? this.refreshTokenExpiry,
      sessionState: sessionState ?? this.sessionState,
      notBeforePolicy: notBeforePolicy ?? this.notBeforePolicy,
      scope: scope ?? this.scope,
    );
  }
}
