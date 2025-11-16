import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;

  SignInParams({
    required this.email,
    required this.password,
  });
}

class SignIn implements UseCase<Session, SignInParams> {
  final AuthRepository authRepository;

  SignIn({required this.authRepository});

  @override
  Future<Either<Failure, Session>> call(SignInParams params) async {
    return await authRepository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}
