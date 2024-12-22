import 'package:chopper/chopper.dart';

extension RequestUtils on Request {
  bool get isAuthRequest => uri.path.contains('/openid-connect/token');
}