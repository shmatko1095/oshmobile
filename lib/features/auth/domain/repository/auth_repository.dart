import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<Either<Failure, Session>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> verifyEmail({
    required String email,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
  });
}
