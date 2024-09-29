import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/user.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class UserSignUpParams {
  final String email;
  final String password;
  final String name;

  UserSignUpParams({
    required this.email,
    required this.password,
    required this.name,
  });
}

class UserSignUp implements UseCase<User, UserSignUpParams> {
  final AuthRepository authRepository;

  UserSignUp({required this.authRepository});

  @override
  Future<Either<Failure, User>> call(UserSignUpParams params) async {
    return await authRepository.signUp(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}
