import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/user.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class UserSignInParams {
  final String email;
  final String password;

  UserSignInParams({
    required this.email,
    required this.password,
  });
}

class UserSignIn implements UseCase<User, UserSignInParams> {
  final AuthRepository authRepository;

  UserSignIn({required this.authRepository});

  @override
  Future<Either<Failure, User>> call(UserSignInParams params) async {
    return await authRepository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}
