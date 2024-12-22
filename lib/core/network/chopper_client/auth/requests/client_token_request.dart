final class ClientTokenRequest {
  final String grantType = "client_credentials";
  final String clientId;
  final String clientSecret;

  ClientTokenRequest({
    required this.clientId,
    required this.clientSecret,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'grant_type': grantType,
        'client_id': clientId,
        'client_secret': clientSecret,
      };
}
