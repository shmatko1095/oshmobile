import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';

class ResetPasswordParams {
  final String email;

  ResetPasswordParams({
    required this.email,
  });
}

class ResetPassword implements UseCase<void, ResetPasswordParams> {
  final AuthRepository authRepository;

  ResetPassword({required this.authRepository});

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await authRepository.resetPassword(
      email: params.email,
    );
  }
}
