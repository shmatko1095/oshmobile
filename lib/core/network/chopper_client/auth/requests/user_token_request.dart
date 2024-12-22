final class UserTokenRequest {
  final String grantType = "password";
  final String clientId;
  final String clientSecret;
  final String username;
  final String password;

  UserTokenRequest({
    required this.username,
    required this.password,
    required this.clientId,
    required this.clientSecret,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'grant_type': grantType,
        'client_id': clientId,
        'client_secret': clientSecret,
        'username': username,
        'password': password,
      };
}
