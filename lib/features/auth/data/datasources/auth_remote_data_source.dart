import 'package:oshmobile/core/common/entities/session.dart';

abstract interface class IAuthRemoteDataSource {
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<Session> signIn({
    required String email,
    required String password,
  });
}
