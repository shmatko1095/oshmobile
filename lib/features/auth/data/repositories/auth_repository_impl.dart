import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final IAuthRemoteDataSource authRemoteDataSource;
  final InternetConnectionChecker connectionChecker;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, Session>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // if (await connectionChecker.isConnected) {
      Session session = await authRemoteDataSource.signIn(
        email: email,
        password: password,
      );
      return right(session);
      // } else {
      //   return left(Failure.noInternetConnection());
      // }
    } on ServerException catch (e) {
      return left(Failure.unexpected(e.message));
    } on InvalidUserCredentialsException catch (e) {
      return left(Failure.invalidUserCredentials());
    } on EmailNotVerifiedException catch (e) {
      return left(Failure.emailNotVerified());
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      // if (await connectionChecker.isConnected) {
      await authRemoteDataSource.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      return right(null);
      // } else {
      //   return left(Failure.noInternetConnection());
      // }
    } on ConflictException catch (e) {
      return left(Failure.conflict());
    } on ServerException catch (e) {
      return left(Failure.unexpected(e.message));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail({
    required String email,
  }) async {
    try {
      // if (await connectionChecker.isConnected) {
      await authRemoteDataSource.verifyEmail(
        email: email,
      );
      return right(null);
      // } else {
      //   return left(Failure.noInternetConnection());
      // }
    } on ServerException catch (e) {
      return left(Failure.unexpected(e.message));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
    try {
      await authRemoteDataSource.resetPassword(
        email: email,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure.unexpected(e.message));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
