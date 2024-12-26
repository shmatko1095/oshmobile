final class SendResetPasswordEmailRequest {
  final String email;

  SendResetPasswordEmailRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
      };
}
