final class Session {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int refreshExpiresIn;
  final String tokenType;
  final String sessionState;
  final int notBeforePolicy;
  final String scope;

  Session({
    this.accessToken = "",
    this.refreshToken = "",
    this.expiresIn = 0,
    this.refreshExpiresIn = 0,
    this.tokenType = "",
    this.sessionState = "",
    this.notBeforePolicy = 0,
    this.scope = "",
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        accessToken: json['access_token'] as String? ?? "",
        refreshToken: json['refresh_token'] as String? ?? "",
        expiresIn: json['expires_in'] as int? ?? 0,
        refreshExpiresIn: json['refresh_expires_in'] as int? ?? 0,
        tokenType: json['token_type'] as String? ?? "",
        sessionState: json['session_state'] as String? ?? "",
        notBeforePolicy: json['not-before-policy'] as int? ?? 0,
        scope: json['scope'] as String? ?? "",
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'refresh_expires_in': refreshExpiresIn,
        'token_type': tokenType,
        'session_state': sessionState,
        'not-before-policy': notBeforePolicy,
        'scope': scope,
      };

  Session copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    int? refreshExpiresIn,
    String? tokenType,
    String? sessionState,
    int? notBeforePolicy,
    String? scope,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      refreshExpiresIn: refreshExpiresIn ?? this.refreshExpiresIn,
      tokenType: tokenType ?? this.tokenType,
      sessionState: sessionState ?? this.sessionState,
      notBeforePolicy: notBeforePolicy ?? this.notBeforePolicy,
      scope: scope ?? this.scope,
    );
  }
}
