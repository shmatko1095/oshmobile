import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class SignInDemo implements UseCase<Session, NoParams> {
  final AuthRepository authRepository;

  SignInDemo({required this.authRepository});

  @override
  Future<Either<Failure, Session>> call(NoParams params) async {
    return await authRepository.signInDemo();
  }
}
