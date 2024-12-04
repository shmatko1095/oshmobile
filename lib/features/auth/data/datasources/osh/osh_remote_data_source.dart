// import 'package:oshmobile/core/common/entities/session.dart' as osh;
import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/web/auth/auth_service.dart';
import 'package:oshmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:oshmobile/features/auth/data/models/user_model.dart';

class OshRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final AuthService _authClient;

  OshRemoteDataSourceImpl({required ChopperClient webClient})
      : _authClient = webClient.getService<AuthService>();

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authClient.signInWithUserCred(
        username: email,
        password: password,
      );
      if (response.isSuccessful) {
        final jwtData = JwtDecoder.decode(response.body["access_token"]);
        return UserModel(
          firstName: jwtData["given_name"],
          lastName: jwtData["family_name"],
          email: jwtData["email"],
          id: jwtData["sub"],
        );
      } else {
        throw ServerException(response.error as String);
      }
    } on ServerException catch (_) {
      rethrow;
    }catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUp({
    String? firstName,
    String? lastName,
    required String email,
    required String password,
  }) async {
    // try {
    //   final response = await supabaseClient.auth.signUp(
    //     email: email,
    //     password: password,
    //     data: {
    //       "firstName": firstName,
    //       "lastName": lastName,
    //     },
    //   );
    //   if (response.user == null) {
    throw ServerException("User is null");
    //   }
    //   return UserModel.fromJson(response.user!.toJson());
    // } on AuthException catch (e) {
    //   throw ServerException(e.message);
    // } catch (e) {
    //   throw ServerException(e.toString());
    // }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    // try {
    // Session? currentUserSession = supabaseClient.auth.currentSession;
    // if (currentUserSession != null) {
    //   final userData = await supabaseClient
    //       .from(Constants.profilesTable)
    //       .select()
    //       .eq("id", currentUserSession.user.id);
    //   return UserModel.fromJson(userData.first)
    //       .copyWith(email: currentUserSession.user.email);
    // }
    // return null;
    // } catch (e) {
    //   throw ServerException(e.toString());
    // }
  }
}
