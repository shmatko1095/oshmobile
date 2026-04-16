import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

extension RequestUtils on Request {
  bool get isAuthRequest =>
      uri.path.contains('/openid-connect/token') ||
      uri.path.contains('/v1/mobile/demo/session');

  bool get isOshApiRequest =>
      uri.scheme == 'https' &&
      uri.host == Uri.parse(AppSecrets.oshApiBaseUrl).host &&
      uri.path.startsWith('/v1/');
}
