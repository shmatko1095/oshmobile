import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class VerifyEmailParams {
  final String email;

  VerifyEmailParams({
    required this.email,
  });
}

class VerifyEmail implements UseCase<void, VerifyEmailParams> {
  final AuthRepository authRepository;

  VerifyEmail({required this.authRepository});

  @override
  Future<Either<Failure, void>> call(VerifyEmailParams params) async {
    return await authRepository.verifyEmail(
      email: params.email,
    );
  }
}
