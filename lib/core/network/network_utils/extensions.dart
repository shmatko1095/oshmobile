import 'package:chopper/chopper.dart';

extension RequestUtils on Request {
  bool get isAuthRequest =>
      uri.path.contains('/openid-connect/token') ||
      uri.path.contains('/v1/mobile/demo/session');
}
