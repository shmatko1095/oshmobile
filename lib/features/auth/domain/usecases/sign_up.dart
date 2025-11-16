import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class UserSignUpParams {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  UserSignUpParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });
}

class SignUp implements UseCase<void, UserSignUpParams> {
  final AuthRepository authRepository;

  SignUp({required this.authRepository});

  @override
  Future<Either<Failure, void>> call(UserSignUpParams params) async {
    return await authRepository.signUp(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      password: params.password,
    );
  }
}
