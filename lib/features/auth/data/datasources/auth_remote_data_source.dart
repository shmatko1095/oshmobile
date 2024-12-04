import 'package:oshmobile/features/auth/data/models/user_model.dart';

abstract interface class IAuthRemoteDataSource {
  Future<UserModel> signUp({
    String? firstName,
    String? lastName,
    required String email,
    required String password,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<UserModel?> getCurrentUserData();
}
