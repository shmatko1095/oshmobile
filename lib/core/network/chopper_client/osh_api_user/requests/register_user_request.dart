final class RegisterUserRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  RegisterUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      };
}
