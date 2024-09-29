import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/user.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/network/connection_checker.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/models/user_model.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final ConnectionChecker connectionChecker;

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => await authRemoteDataSource.signIn(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => await authRemoteDataSource.signUp(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<Either<Failure, User>> _getUser(Future<User> Function() fn) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(Failure("No internet connection"));
      }
      final user = await fn();
      return right(user);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } on Exception catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> currentUser() async {
    try {
      if (!await connectionChecker.isConnected) {
        final session = authRemoteDataSource.currentUserSession;
        if (session == null) {
          return left(Failure("User not logged in!"));
        }
        return right(UserModel(
            id: session.user.id, email: session.user.email ?? "", name: ""));
      }

      final user = await authRemoteDataSource.getCurrentUserData();
      if (user == null) {
        return left(Failure("User not logged in!"));
      }
      return right(user);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
