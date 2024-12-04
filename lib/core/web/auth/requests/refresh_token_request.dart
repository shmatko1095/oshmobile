final class RefreshTokenRequest {
  final String grantType = "refresh_token";
  final String clientId;
  final String clientSecret;
  final String refreshToken;

  RefreshTokenRequest({
    required this.clientId,
    required this.clientSecret,
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'grant_type': grantType,
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
      };
}
